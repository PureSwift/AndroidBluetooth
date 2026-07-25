//
//  AndroidCentralEvents.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/25/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import SwiftJava
import JavaUtil
import JavaLangUtil
import Bluetooth
import GATT

// MARK: - Callback Events

/// Entry points for Bluetooth callback events crossing the JNI bridge.
///
/// The Kotlin callback adapters (`org.pureswift.bluetooth.le.ScanCallback` and
/// `org.pureswift.bluetooth.BluetoothGattCallback`) extract primitive values from the
/// Android callback objects and forward them through the generated `AndroidBluetoothBridge`
/// Java class, which calls these methods after resolving the central via ``AndroidCentralRegistry``.
@available(Android 18, *)
package extension AndroidCentral {

    // MARK: Scan Events

    func handleScanResult(
        callbackType: Int32,
        address: String,
        rssi: Int32,
        isConnectable: Bool,
        advertisementData: Data
    ) {
        log?("\(type(of: self)): \(#function) address: \(address) rssi: \(rssi)")
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let scanData = ScanData(
            peripheral: peripheral,
            date: Date(),
            rssi: Double(rssi),
            advertisementData: AndroidLowEnergyAdvertisementData(data: advertisementData),
            isConnectable: isConnectable
        )
        Task {
            await storage.update { state in
                state.scan.continuation?.yield(scanData)
                state.scan.peripherals[scanData.peripheral] = InternalState.Scan.Device(
                    scanData: scanData
                )
            }
        }
    }

    func handleScanFailed(errorCode: Int32) {
        log?("\(type(of: self)): \(#function) error: \(errorCode)")

        // TODO: Map error codes
        let error = AndroidCentralError.scanFailed(errorCode)

        /*
         static var SCAN_FAILED_ALREADY_STARTED
         static var SCAN_FAILED_APPLICATION_REGISTRATION_FAILED
         static var SCAN_FAILED_FEATURE_UNSUPPORTED
         static var SCAN_FAILED_INTERNAL_ERROR
         */

        Task {
            await storage.update { state in
                state.scan.continuation?.finish(throwing: error)
            }
        }
    }

    // MARK: GATT Events

    func handleConnectionStateChange(
        address: String,
        status: Int32,
        newState: Int32
    ) {
        let log = self.log
        let status = BluetoothGatt.Status(rawValue: status)
        guard let newState = BluetoothConnectionState(rawValue: newState) else {
            assertionFailure()
            return
        }
        log?("\(type(of: self)): \(#function) \(status) \(newState)")
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        Task {
            await storage.update { state in
                switch (status, newState) {
                case (.success, .connected):
                    log?("\(peripheral) Connected")
                    // if we are expecting a new connection
                    if state.cache[peripheral]?.continuation.connect != nil {
                        state.cache[peripheral]?.continuation.connect?.resume()
                        state.cache[peripheral]?.continuation.connect = nil
                    }
                case (.success, .disconnected):
                    log?("\(peripheral) Disconnected")
                    state.cache[peripheral] = nil
                default:
                    log?("\(peripheral) Status Error")
                    state.cache[peripheral]?.continuation.connect?.resume(throwing: AndroidCentralError.gattStatus(status))
                    state.cache[peripheral]?.continuation.connect = nil
                }
            }
        }
    }

    func handleServicesDiscovered(
        address: String,
        status: Int32
    ) {
        let log = self.log
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) Status: \(status)")

        Task {
            await storage.update { state in
                // success discovering
                switch status {
                case .success:
                    guard let cache = state.cache[peripheral],
                        let javaServices = cache.gatt.getServices()?.toArray().map({ $0!.as(BluetoothGattService.self)! }),
                        let services = state.cache[peripheral]?.update(javaServices) else {
                        assertionFailure()
                        return
                    }
                    state.cache[peripheral]?.continuation.discoverServices?.resume(returning: services)
                default:
                    state.cache[peripheral]?.continuation.discoverServices?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.discoverServices = nil
            }
        }
    }

    func handleCharacteristicChanged(
        address: String,
        uuid: String,
        instanceID: Int32,
        value: Data
    ) {
        log?("\(type(of: self)): \(#function) \(uuid)")
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }

        Task {
            await storage.update { state in

                guard let cache = state.cache[peripheral] else {
                    assertionFailure("Invalid cache for \(uuid)")
                    return
                }

                let id = Cache.identifier(
                    peripheral: peripheral,
                    type: .characteristic,
                    instanceID: instanceID,
                    uuid: uuid
                )

                guard let characteristicCache = cache.characteristics.values[id] else {
                    assertionFailure("Invalid identifier for \(uuid)")
                    return
                }

                guard let notification = characteristicCache.notification else {
                    assertionFailure("Unexpected notification for \(uuid)")
                    return
                }

                notification.yield(value)
            }
        }
    }

    func handleCharacteristicRead(
        address: String,
        uuid: String,
        instanceID: Int32,
        value: Data,
        status: Int32
    ) {
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(peripheral) Status: \(status)")

        Task {
            await storage.update { state in
                switch status {
                case .success:
                    state.cache[peripheral]?.continuation.readCharacteristic?.resume(returning: value)
                default:
                    state.cache[peripheral]?.continuation.readCharacteristic?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readCharacteristic = nil
            }
        }
    }

    func handleCharacteristicWrite(
        address: String,
        uuid: String,
        instanceID: Int32,
        status: Int32
    ) {
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(uuid) Status: \(status)")

        Task {
            await storage.update { state in
                switch status {
                case .success:
                    state.cache[peripheral]?.continuation.writeCharacteristic?.resume()
                default:
                    state.cache[peripheral]?.continuation.writeCharacteristic?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.writeCharacteristic = nil
            }
        }
    }

    func handleDescriptorRead(
        address: String,
        uuid: String,
        value: Data,
        status: Int32
    ) {
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(uuid) Status: \(status)")

        Task {
            await storage.update { state in
                switch status {
                case .success:
                    state.cache[peripheral]?.continuation.readDescriptor?.resume(returning: value)
                default:
                    state.cache[peripheral]?.continuation.readDescriptor?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readDescriptor = nil
            }
        }
    }

    func handleDescriptorWrite(
        address: String,
        uuid: String,
        status: Int32
    ) {
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(uuid) Status: \(status)")

        Task {
            await storage.update { state in
                switch status {
                case .success:
                    state.cache[peripheral]?.continuation.writeDescriptor?.resume()
                default:
                    state.cache[peripheral]?.continuation.writeDescriptor?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.writeDescriptor = nil
            }
        }
    }

    func handleMtuChanged(
        address: String,
        mtu: Int32,
        status: Int32
    ) {
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) Peripheral \(peripheral) MTU \(mtu) Status \(status)")

        let oldMTU = options.maximumTransmissionUnit

        Task {
            await storage.update { state in

                // get new MTU value
                guard let newMTU = MaximumTransmissionUnit(rawValue: UInt16(mtu)) else {
                    assertionFailure("Invalid MTU \(mtu)")
                    return
                }

                assert(newMTU <= oldMTU, "Invalid MTU: \(newMTU) > \(oldMTU)")

                // cache new MTU value
                state.cache[peripheral]?.maximumTransmissionUnit = newMTU

                // pending MTU exchange
                state.cache[peripheral]?.continuation.exchangeMTU?.resume(returning: newMTU)
                state.cache[peripheral]?.continuation.exchangeMTU = nil
            }
        }
    }

    func handlePhyRead(
        address: String,
        txPhy: Int32,
        rxPhy: Int32,
        status: Int32
    ) {
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(status)")
    }

    func handlePhyUpdate(
        address: String,
        txPhy: Int32,
        rxPhy: Int32,
        status: Int32
    ) {
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(status)")
    }

    func handleReadRemoteRssi(
        address: String,
        rssi: Int32,
        status: Int32
    ) {
        guard let peripheral = Peripheral(address: address) else {
            assertionFailure("Invalid address \(address)")
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(rssi) \(status)")

        Task {
            await storage.update { state in
                switch status {
                case .success:
                    state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(returning: Int(rssi))
                default:
                    state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readRemoteRSSI = nil
            }
        }
    }

    func handleReliableWriteCompleted(
        address: String,
        status: Int32
    ) {
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(status)")
    }
}
