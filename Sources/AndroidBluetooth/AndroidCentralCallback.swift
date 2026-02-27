//
//  AndroidCentralCallback.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
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

extension AndroidCentral {
    
    @JavaClass("org.pureswift.bluetooth.le.ScanCallback")
    internal class LowEnergyScanCallback: AndroidBluetooth.ScanCallback {
        
        @JavaMethod
        @_nonoverride convenience init(swiftPeer: Int64, environment: JNIEnvironment? = nil)
        
        convenience init(central: AndroidCentral, environment: JNIEnvironment? = nil) {
            // Get Swift pointer to AndroidCentral
            let swiftPeer = Int64(bitPattern: UInt64(UInt(bitPattern: Unmanaged.passUnretained(central).toOpaque())))
            self.init(swiftPeer: swiftPeer, environment: environment)
            assert(getSwiftPeer() == swiftPeer)
        }
        
        @JavaMethod
        func setSwiftPeer(_ swiftPeer: Int64)
        
        @JavaMethod
        func getSwiftPeer() -> Int64
        
        @JavaMethod
        override func finalize()
        
        
    }
}

private extension AndroidCentral.LowEnergyScanCallback {
    
    func central(_ swiftPeer: Int64) -> AndroidCentral? {
        // Get the Swift peer pointer from Java/Kotlin side
        guard swiftPeer != 0 else {
            return nil
        }
        // Convert back to AndroidCentral reference
        let pointer = UnsafeRawPointer(bitPattern: Int(truncatingIfNeeded: swiftPeer))
        guard let pointer else {
            return nil
        }
        return Unmanaged<AndroidCentral>.fromOpaque(pointer).takeUnretainedValue()
    }
}

@JavaImplementation("org.pureswift.bluetooth.le.ScanCallback")
extension AndroidCentral.LowEnergyScanCallback {
    
    @JavaMethod
    func swiftRelease(_ swiftPeer: Int64) {
        setSwiftPeer(0)
    }
    
    @JavaMethod
    func swiftOnScanResult(
        _ swiftPeer: Int64,
        error: Int32,
        result: AndroidBluetooth.ScanResult?
    ) {
        guard let central = central(swiftPeer),
            let result,
            let scanData = try? ScanData(result) else {
            assertionFailure()
            return
        }
        //
        central.log?("\(type(of: self)): \(#function) name: \((try? result.getDevice().getName()) ?? "") address: \(result.getDevice().getAddress())")
        
        Task {
            await central.storage.update { state in
                state.scan.continuation?.yield(scanData)
                state.scan.peripherals[scanData.peripheral] = AndroidCentral.InternalState.Scan.Device(
                    scanData: scanData,
                    scanResult: result
                )
            }
        }
    }
    
    @JavaMethod
    func swiftOnBatchScanResults(_ swiftPeer: Int64, results: [AndroidBluetooth.ScanResult?]) {
        guard let central = central(swiftPeer) else {
            return
        }
        central.log?("\(type(of: self)): \(#function)")
        for result in results {
            guard let result, let scanData = try? ScanData(result) else {
                assertionFailure()
                return
            }
            Task {
                await central.storage.update { state in
                    state.scan.continuation?.yield(scanData)
                    state.scan.peripherals[scanData.peripheral] = AndroidCentral.InternalState.Scan.Device(
                        scanData: scanData,
                        scanResult: result
                    )
                }
            }
        }
    }
    
    @JavaMethod
    func swiftOnScanFailed(_ swiftPeer: Int64, error: Int32) {
        let central = central(swiftPeer)
        central?.log?("\(type(of: self)): \(#function)")
        
        // TODO: Map error codes
        let error = AndroidCentralError.scanFailed(error)
        
        /*
         static var SCAN_FAILED_ALREADY_STARTED
         static var SCAN_FAILED_APPLICATION_REGISTRATION_FAILED
         static var SCAN_FAILED_FEATURE_UNSUPPORTED
         static var SCAN_FAILED_INTERNAL_ERROR
         */
        
        Task {
            await central?.storage.update { state in
                state.scan.continuation?.finish(throwing: error)
            }
        }
    }
}

extension AndroidCentral {

    @JavaClass("org.pureswift.bluetooth.BluetoothGattCallback")
    class GattCallback: AndroidBluetooth.BluetoothGattCallback {

        @JavaMethod
        @_nonoverride convenience init(swiftPeer: Int64, environment: JNIEnvironment? = nil)

        convenience init(central: AndroidCentral, environment: JNIEnvironment? = nil) {
            let swiftPeer = Int64(bitPattern: UInt64(UInt(bitPattern: Unmanaged.passUnretained(central).toOpaque())))
            self.init(swiftPeer: swiftPeer, environment: environment)
            assert(getSwiftPeer() == swiftPeer)
        }

        @JavaMethod
        func setSwiftPeer(_ swiftPeer: Int64)

        @JavaMethod
        func getSwiftPeer() -> Int64

        @JavaMethod
        override func finalize()
    }
}

private extension AndroidCentral.GattCallback {

    func central(_ swiftPeer: Int64) -> AndroidCentral? {
        guard swiftPeer != 0 else {
            return nil
        }
        let pointer = UnsafeRawPointer(bitPattern: Int(truncatingIfNeeded: swiftPeer))
        guard let pointer else {
            return nil
        }
        return Unmanaged<AndroidCentral>.fromOpaque(pointer).takeUnretainedValue()
    }
}

@JavaImplementation("org.pureswift.bluetooth.BluetoothGattCallback")
extension AndroidCentral.GattCallback {

    @JavaMethod
    func swiftRelease(_ swiftPeer: Int64) {
        setSwiftPeer(0)
    }

    /**
     Callback indicating when GATT client has connected/disconnected to/from a remote GATT server.

     Parameters
     - gatt    BluetoothGatt: GATT client
     - status    int: Status of the connect or disconnect operation. BluetoothGatt.GATT_SUCCESS if the operation succeeds.
     - newState    int: Returns the new connection state. Can be one of BluetoothProfile.STATE_DISCONNECTED or BluetoothProfile.STATE_CONNECTED
     */
    @JavaMethod
    func swiftOnConnectionStateChange(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        status: Int32,
        newState: Int32
    ) {
        let central = central(swiftPeer)
        let log = central?.log
        let status = BluetoothGatt.Status(rawValue: status)
        guard let central,
            let gatt,
            let newState = BluetoothConnectionState(rawValue: newState) else {
            assertionFailure()
            return
        }
        log?("\(type(of: self)): \(#function) \(status) \(newState)")
        let peripheral = Peripheral(gatt)
        Task {
            await central.storage.update { state in
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

    @JavaMethod
    func swiftOnServicesDiscovered(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        status: Int32
    ) {
        let central = central(swiftPeer)
        guard let central, let gatt else {
            assertionFailure()
            return
        }
        let log = central.log
        let peripheral = Peripheral(gatt)
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) Status: \(status)")

        Task {
            await central.storage.update { state in
                // success discovering
                switch status {
                case .success:
                    guard let javaServices = gatt.getServices()?.toArray().map({ $0!.as(BluetoothGattService.self)! }),
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

    @JavaMethod
    func swiftOnCharacteristicChanged(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?
    ) {
        let central = central(swiftPeer)
        guard let central, let gatt, let characteristic else {
            assertionFailure()
            return
        }
        let log = central.log
        log?("\(type(of: self)): \(#function)")

        let peripheral = Peripheral(gatt)

        Task {
            await central.storage.update { state in

                guard let uuid = characteristic.getUuid()?.toString() else {
                    assertionFailure()
                    return
                }

                guard let cache = state.cache[peripheral] else {
                    assertionFailure("Invalid cache for \(uuid)")
                    return
                }

                let id = cache.identifier(for: characteristic)

                let bytes = characteristic.getValue()

                // TODO: Replace usage of Foundation.Data with byte array to prevent copying
                let data = Data(unsafeBitCast(bytes, to: [UInt8].self))

                guard let characteristicCache = cache.characteristics.values[id] else {
                    assertionFailure("Invalid identifier for \(uuid)")
                    return
                }

                guard let notification = characteristicCache.notification else {
                    assertionFailure("Unexpected notification for \(uuid)")
                    return
                }

                notification.yield(data)
            }
        }
    }

    @JavaMethod
    func swiftOnCharacteristicRead(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?,
        status: Int32
    ) {
        let central = central(swiftPeer)
        guard let central, let gatt, let characteristic else {
            assertionFailure()
            return
        }
        let log = central.log
        let peripheral = Peripheral(gatt)
        let status = BluetoothGatt.Status(rawValue: status)
        log?("\(type(of: self)): \(#function) \(peripheral) Status: \(status)")

        Task {
            await central.storage.update { state in

                switch status {
                case .success:
                    let bytes = characteristic.getValue()
                    let data = Data(unsafeBitCast(bytes, to: [UInt8].self))
                    state.cache[peripheral]?.continuation.readCharacteristic?.resume(returning: data)
                default:
                    state.cache[peripheral]?.continuation.readCharacteristic?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readCharacteristic = nil
            }
        }
    }

    @JavaMethod
    func swiftOnCharacteristicWrite(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?,
        status: Int32
    ) {
        let central = central(swiftPeer)
        guard let central, let gatt else {
            assertionFailure()
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        central.log?("\(type(of: self)): \(#function)")
        let peripheral = Peripheral(gatt)

        Task {
            await central.storage.update { state in
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

    @JavaMethod
    func swiftOnDescriptorRead(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        descriptor: BluetoothGattDescriptor?,
        status: Int32
    ) {
        let central = central(swiftPeer)
        guard let central, let gatt, let descriptor else {
            assertionFailure()
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        let peripheral = Peripheral(gatt)

        guard let uuid = descriptor.getUuid()?.toString() else {
            assertionFailure()
            return
        }

        central.log?(" \(type(of: self)): \(#function) \(uuid)")

        Task {
            await central.storage.update { state in

                switch status {
                case .success:
                    let bytes = descriptor.getValue()
                    let data = Data(unsafeBitCast(bytes, to: [UInt8].self))
                    state.cache[peripheral]?.continuation.readDescriptor?.resume(returning: data)
                default:
                    state.cache[peripheral]?.continuation.readDescriptor?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readDescriptor = nil
            }
        }
    }

    @JavaMethod
    func swiftOnDescriptorWrite(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        descriptor: BluetoothGattDescriptor?,
        status: Int32
    ) {
        let central = central(swiftPeer)
        guard let central, let gatt, let descriptor else {
            assertionFailure()
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        let peripheral = Peripheral(gatt)

        guard let uuid = descriptor.getUuid()?.toString() else {
            assertionFailure()
            return
        }

        central.log?(" \(type(of: self)): \(#function) \(uuid)")

        Task {
            await central.storage.update { state in
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

    @JavaMethod
    func swiftOnMtuChanged(
        _ swiftPeer: Int64,
        gatt: BluetoothGatt?,
        mtu: Int32,
        status: Int32
    ) {
        let central = central(swiftPeer)
        guard let central, let gatt else {
            assertionFailure()
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        central.log?("\(type(of: self)): \(#function) Peripheral \(Peripheral(gatt)) MTU \(mtu) Status \(status)")

        let peripheral = Peripheral(gatt)

        let oldMTU = central.options.maximumTransmissionUnit

        Task {
            await central.storage.update { state in

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
                return
            }
        }
    }

    @JavaMethod
    func swiftOnPhyRead(_ swiftPeer: Int64, gatt: BluetoothGatt?, txPhy: Int32, rxPhy: Int32, status: Int32) {
        let status = BluetoothGatt.Status(rawValue: status)
        central(swiftPeer)?.log?("\(type(of: self)): \(#function) \(status)")
    }

    @JavaMethod
    func swiftOnPhyUpdate(_ swiftPeer: Int64, gatt: BluetoothGatt?, txPhy: Int32, rxPhy: Int32, status: Int32) {
        let status = BluetoothGatt.Status(rawValue: status)
        central(swiftPeer)?.log?("\(type(of: self)): \(#function) \(status)")
    }

    @JavaMethod
    func swiftOnReadRemoteRssi(_ swiftPeer: Int64, gatt: BluetoothGatt?, rssi: Int32, status: Int32) {
        let central = central(swiftPeer)
        guard let central, let gatt else {
            assertionFailure()
            return
        }
        let status = BluetoothGatt.Status(rawValue: status)
        central.log?("\(type(of: self)): \(#function) \(rssi) \(status)")

        let peripheral = Peripheral(gatt)

        Task {
            await central.storage.update { state in
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

    @JavaMethod
    func swiftOnReliableWriteCompleted(_ swiftPeer: Int64, gatt: BluetoothGatt?, status: Int32) {
        let status = BluetoothGatt.Status(rawValue: status)
        central(swiftPeer)?.log?("\(type(of: self)): \(#function) \(status)")
    }
}
