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
        
        init(central: AndroidCentral, environment: JNIEnvironment?) {
            self.central = central
        }
    }
}

@JavaImplementation("org.pureswift.bluetooth.le.ScanCallback")
extension AndroidCentral.LowEnergyScanCallback {
    
    @JavaMethod
    func onScanResultSwift(_ error: Int32, _ result: AndroidBluetooth.ScanResult?) {
        guard let central else {
            return
        }
        central.log?("\(type(of: self)): \(#function) name: \(result.getDevice().getName() ?? "") address: \(result.getDevice().getAddress())")
        guard let result, let scanData = try? ScanData(result) else {
            assertionFailure()
            return
        }
        Task {
            await central.storage.update { state in
                state.scan.continuation?.yield(scanData)
                state.scan.peripherals[scanData.peripheral] = InternalState.Scan.Device(
                    scanData: scanData,
                    scanResult: result
                )
            }
        }
    }
    
    @JavaMethod
    func onBatchScanResultsSwift(results: [AndroidBluetooth.ScanResult?]) {
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

extension AndroidCentral {
    
    @JavaClass("org.pureswift.bluetooth.BluetoothGattCallback")
    internal class GattCallback: AndroidBluetooth.BluetoothGattCallback {
        
        private weak var central: AndroidCentral?
        
        /*
        convenience init(central: AndroidCentral) {
            self.init(javaObject: nil)
            bindNewJavaObject()
            
            self.central = central
        }
        
        public required init(javaObject: jobject?) {
            super.init(javaObject: javaObject)
        }
        
        public override func onConnectionStateChange(
            gatt: Android.Bluetooth.Gatt,
            status: Android.Bluetooth.Gatt.Status,
            newState: Android.Bluetooth.Device.State
        ) {
            let log = central?.log
            log?("\(type(of: self)): \(#function)")
            log?("Status: \(status) - newState: \(newState)")
            
            let peripheral = Peripheral(gatt)
            
            Task {
                await central?.storage.update { state in
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
                        state.cache[peripheral]?.continuation.connect?.resume(throwing: status) // throw `status` error
                        state.cache[peripheral]?.continuation.connect = nil
                    }
                }
            }
        }
        
        public override func onServicesDiscovered(
            gatt: Android.Bluetooth.Gatt,
            status: Android.Bluetooth.Gatt.Status
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
                        state.cache[peripheral]?.continuation.discoverServices?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.discoverServices = nil
                }
            }
        }
        
        public override func onCharacteristicChanged(
            gatt: Android.Bluetooth.Gatt,
            characteristic: Android.Bluetooth.GattCharacteristic
        ) {
            let log = central?.log
            log?("\(type(of: self)): \(#function)")
            
            let peripheral = Peripheral(gatt)
                        
            Task {
                await central?.storage.update { state in
                    
                    guard let uuid = characteristic.getUUID().toString() else {
                        assertionFailure()
                        return
                    }
                    
                    guard let cache = state.cache[peripheral] else {
                        assertionFailure("Invalid cache for \(uuid)")
                        return
                    }
                    
                    let id = cache.identifier(for: characteristic)
                    
                    let data = characteristic.getValue()
                        .map { Data(unsafeBitCast($0, to: [UInt8].self)) } ?? Data()
                    
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
        
        public override func onCharacteristicRead(
            gatt: Android.Bluetooth.Gatt,
            characteristic: Android.Bluetooth.GattCharacteristic,
            status: Android.Bluetooth.Gatt.Status
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
                        state.cache[peripheral]?.continuation.readCharacteristic?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.readCharacteristic = nil
                }
            }
        }
        
        public override func onCharacteristicWrite(
            gatt: Android.Bluetooth.Gatt,
            characteristic: Android.Bluetooth.GattCharacteristic,
            status: Android.Bluetooth.Gatt.Status
        ) {
            central?.log?("\(type(of: self)): \(#function)")
            
            let peripheral = Peripheral(gatt)
            
            Task {
                await central?.storage.update { state in
                    switch status {
                    case .success:
                        state.cache[peripheral]?.continuation.writeCharacteristic?.resume()
                    default:
                        state.cache[peripheral]?.continuation.writeCharacteristic?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.writeCharacteristic = nil
                }
            }
        }
        
        public override func onDescriptorRead(
            gatt: Android.Bluetooth.Gatt,
            descriptor: Android.Bluetooth.GattDescriptor,
            status: Android.Bluetooth.Gatt.Status
        ) {
            let peripheral = Peripheral(gatt)
            
            guard let uuid = descriptor.getUUID().toString() else {
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
                        state.cache[peripheral]?.continuation.readDescriptor?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.readDescriptor = nil
                }
            }
        }
        
        public override func onDescriptorWrite(
            gatt: Android.Bluetooth.Gatt,
            descriptor: Android.Bluetooth.GattDescriptor,
            status: AndroidBluetoothGatt.Status
        ) {
            
            let peripheral = Peripheral(gatt)
            
            guard let uuid = descriptor.getUUID().toString() else {
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
                        state.cache[peripheral]?.continuation.writeDescriptor?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.writeDescriptor = nil
                }
            }
        }
        
        public override func onMtuChanged(
            gatt: Android.Bluetooth.Gatt,
            mtu: Int,
            status: Android.Bluetooth.Gatt.Status
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
        
        public override func onPhyRead(gatt: Android.Bluetooth.Gatt, txPhy: Android.Bluetooth.Gatt.TxPhy, rxPhy: Android.Bluetooth.Gatt.RxPhy, status: AndroidBluetoothGatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function)")
        }
        
        public override func onPhyUpdate(gatt: Android.Bluetooth.Gatt, txPhy: Android.Bluetooth.Gatt.TxPhy, rxPhy: Android.Bluetooth.Gatt.RxPhy, status: AndroidBluetoothGatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function)")
        }
        
        public override func onReadRemoteRssi(gatt: Android.Bluetooth.Gatt, rssi: Int, status: Android.Bluetooth.Gatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function) \(rssi) \(status)")
            
            let peripheral = Peripheral(gatt)
            
            Task {
                await central?.storage.update { state in
                    switch status {
                    case .success:
                        state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(returning: rssi)
                    default:
                        state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.readRemoteRSSI = nil
                }
            }
        }
        
        public override func onReliableWriteCompleted(gatt: Android.Bluetooth.Gatt, status: AndroidBluetoothGatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function)")
        }*/
    }
}
