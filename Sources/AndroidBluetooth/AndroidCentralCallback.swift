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
import JavaKit
import JavaUtil
import Bluetooth
import GATT

extension AndroidCentral {
    
    @JavaClass("org.pureswift.bluetooth.le.ScanCallback")
    internal class LowEnergyScanCallback: AndroidBluetooth.ScanCallback {
        
        weak var central: AndroidCentral?
        
        @JavaMethod
        @_nonoverride convenience init(environment: JNIEnvironment? = nil)
        
        convenience init(central: AndroidCentral, environment: JNIEnvironment? = nil) {
            self.init(environment: environment)
            self.central = central
        }
    }
}

@JavaImplementation("org.pureswift.bluetooth.le.ScanCallback")
extension AndroidCentral.LowEnergyScanCallback {
    
    @JavaMethod
    func onScanResult(error: Int32, result: AndroidBluetooth.ScanResult?) {
        guard let central else {
            return
        }
        guard let result, let scanData = try? ScanData(result) else {
            assertionFailure()
            return
        }
        central.log?("\(type(of: self)): \(#function) name: \(result.getDevice().getName() ?? "") address: \(result.getDevice().getAddress())")
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
    func onBatchScanResults(results: [AndroidBluetooth.ScanResult?]) {
        guard let central else {
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
    func onScanFailedSwift(error: Int32) {
        
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

@JavaClass("org.pureswift.bluetooth.BluetoothGattCallback")
class GattCallback: AndroidBluetooth.BluetoothGattCallback {
    
    weak var central: AndroidCentral?
    
    @JavaMethod
    @_nonoverride convenience init(environment: JNIEnvironment? = nil)
    
    convenience init(central: AndroidCentral, environment: JNIEnvironment? = nil) {
        self.init(environment: environment)
        self.central = central
    }
}

@JavaImplementation("org.pureswift.bluetooth.BluetoothGattCallback")
extension GattCallback {
    
    /**
     Callback indicating when GATT client has connected/disconnected to/from a remote GATT server.

     Parameters
     - gatt    BluetoothGatt: GATT client
     - status    int: Status of the connect or disconnect operation. BluetoothGatt.GATT_SUCCESS if the operation succeeds.
     - newState    int: Returns the new connection state. Can be one of BluetoothProfile.STATE_DISCONNECTED or BluetoothProfile.STATE_CONNECTED
     */
    @JavaMethod
    func onConnectionStateChange(
        gatt: BluetoothGatt?,
        status: Int32,
        newState: Int32
    ) {
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
    /*
    @JavaMethod
    public func onServicesDiscovered(
        gatt: BluetoothGatt?,
        status: Int32
    ) {
        let log = central?.log
        let peripheral = Peripheral(gatt)
        log?("\(type(of: self)): \(#function) Status: \(status)")
        
        Task {
            await central?.storage.update { state in
                // success discovering
                switch status {
                case .success:
                    guard let services = state.cache[peripheral]?.update(gatt.services) else {
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
    public func onCharacteristicChanged(
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?
    ) {
        let log = central?.log
        log?("\(type(of: self)): \(#function)")
        
        let peripheral = Peripheral(gatt)
                    
        Task {
            await central?.storage.update { state in
                
                guard let uuid = characteristic.getUuid().toString() else {
                    assertionFailure()
                    return
                }
                
                guard let cache = state.cache[peripheral] else {
                    assertionFailure("Invalid cache for \(uuid)")
                    return
                }
                
                let id = cache.identifier(for: characteristic)
                
                let data = characteristic.getValue()
                    .map { Data(unsafeBitCast($0, to: [UInt8].self)) } ?? .init()
                
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
    public func onCharacteristicRead(
        gatt: BluetoothGatt!,
        characteristic: BluetoothGattCharacteristic!,
        status: Int32
    ) {
        let log = central?.log
        let peripheral = Peripheral(gatt)
        log?("\(type(of: self)): \(#function) \(peripheral) Status: \(status)")
        
        Task {
            await central?.storage.update { state in
                                    
                switch status {
                case .success:
                    let data = characteristic.getValue()
                        .map { Data(unsafeBitCast($0, to: [UInt8].self)) } ?? Data()
                    state.cache[peripheral]?.continuation.readCharacteristic?.resume(returning: data)
                default:
                    state.cache[peripheral]?.continuation.readCharacteristic?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readCharacteristic = nil
            }
        }
    }
    
    @JavaMethod
    public func onCharacteristicWrite(
        gatt: BluetoothGatt!,
        characteristic: BluetoothGattCharacteristic!,
        status: Int32
    ) {
        central?.log?("\(type(of: self)): \(#function)")
        
        let peripheral = Peripheral(gatt)
        
        Task {
            await central?.storage.update { state in
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
    public func onDescriptorRead(
        gatt: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        status: Int32
    ) {
        let peripheral = Peripheral(gatt)
        
        guard let uuid = descriptor.getUuid().toString() else {
            assertionFailure()
            return
        }
        
        central?.log?(" \(type(of: self)): \(#function) \(uuid)")
        
        Task {
            await central?.storage.update { state in
                                    
                switch status {
                case .success:
                    let data = descriptor.getValue()
                        .map { Data(unsafeBitCast($0, to: [UInt8].self)) } ?? Data()
                    state.cache[peripheral]?.continuation.readDescriptor?.resume(returning: data)
                default:
                    state.cache[peripheral]?.continuation.readDescriptor?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readDescriptor = nil
            }
        }
    }
    
    @JavaMethod
    public func onDescriptorWrite(
        gatt: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        status: Int32
    ) {
        
        let peripheral = Peripheral(gatt)
        
        guard let uuid = descriptor.getUuid().toString() else {
            assertionFailure()
            return
        }
        
        central?.log?(" \(type(of: self)): \(#function) \(uuid)")
        
        Task {
            await central?.storage.update { state in
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
    public func onMtuChanged(
        gatt: BluetoothGatt,
        mtu: Int,
        status: Int32
    ) {
        central?.log?("\(type(of: self)): \(#function) Peripheral \(Peripheral(gatt)) MTU \(mtu) Status \(status)")
        
        let peripheral = Peripheral(gatt)
        
        guard let central = self.central else {
            assertionFailure()
            return
        }
        
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
    public func onPhyRead(gatt: BluetoothGatt, txPhy: Int32, rxPhy: Int32, status: Int32) {
        
        central?.log?("\(type(of: self)): \(#function)")
    }
    
    @JavaMethod
    public func onPhyUpdate(gatt: BluetoothGatt, txPhy: Int32, rxPhy: Int32, status: Int32) {
        
        central?.log?("\(type(of: self)): \(#function)")
    }
    
    @JavaMethod
    public func onReadRemoteRssi(gatt: BluetoothGatt, rssi: Int32, status: Int32) {
        
        central?.log?("\(type(of: self)): \(#function) \(rssi) \(status)")
        
        let peripheral = Peripheral(gatt)
        
        Task {
            await central?.storage.update { state in
                switch status {
                case .success:
                    state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(returning: rssi)
                default:
                    state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(throwing: AndroidCentralError.gattStatus(status))
                }
                state.cache[peripheral]?.continuation.readRemoteRSSI = nil
            }
        }
    }
    
    @JavaMethod
    public override func onReliableWriteCompleted(gatt: BluetoothGatt, status: Int32) {
        
        central?.log?("\(type(of: self)): \(#function)")
    }*/
}
