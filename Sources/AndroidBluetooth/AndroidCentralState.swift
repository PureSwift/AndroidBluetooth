//
//  AndroidCentralState.swift
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

internal extension AndroidCentral {
    
    actor Storage {
        
        var state = InternalState()
        
        func update<T>(_ block: (inout InternalState) throws -> (T)) rethrows -> T {
            return try block(&state)
        }
    }
    
    struct InternalState {
        
        init() { }
        
        var cache = [Peripheral: Cache]()
        
        var scan = Scan()
        
        struct Scan {
            
            var peripherals = [Peripheral: Device]()
            
            var continuation: AsyncIndefiniteStream<ScanData<Peripheral, AndroidCentral.Advertisement>>.Continuation?
            
            var callback: ScanCallback?
            
            struct Device {
                
                let scanData: ScanData<Peripheral, AndroidLowEnergyAdvertisementData>
                
                let scanResult: AndroidBluetooth.ScanResult
            }
        }
    }
    
    /// GATT cache for a connection or peripheral.
    struct Cache {
        
        init(
            gatt: BluetoothGatt,
            callback: GattCallback
        ) {
            self.gatt = gatt
            self.gattCallback = callback
        }
        
        let gattCallback: GattCallback
        
        let gatt: BluetoothGatt
        
        fileprivate(set) var maximumTransmissionUnit: MaximumTransmissionUnit = .default
        
        var services = Services()
        
        var characteristics = Characteristics()
        
        var descriptors = Descriptors()
        
        var continuation = PeripheralContinuation()
        
        func identifier<T>(for attribute: T) -> AndroidCentral.AttributeID where T: AndroidCentralAttribute {
            let peripheral = Peripheral(gatt)
            let instanceID = attribute.getInstanceId()
            guard let uuid = attribute.getUuid()?.toString() else {
                assertionFailure()
                return instanceID.description
            }
            return "\(peripheral.id)/\(T.attributeType)/\(instanceID)/\(uuid)"
        }
        
        func identifier(
            for descriptor: BluetoothGattDescriptor,
            characteristic: Characteristic<Peripheral, AttributeID>
        ) -> AndroidCentral.AttributeID {
            guard let uuid = descriptor.getUuid()?.toString() else {
                fatalError()
            }
            return characteristic.id + "/Descriptor/\(uuid)"
        }
        
        mutating func update(_ newValues: [BluetoothGattService]) -> [Service<Peripheral, AttributeID>] {
            // reset caches
            services.values.removeAll(keepingCapacity: true)
            characteristics.values.removeAll(keepingCapacity: true)
            descriptors.values.removeAll(keepingCapacity: true)
            // return mapped values
            return newValues.map {
                let id = identifier(for: $0)
                let peripheral = Peripheral(gatt)
                let uuid = BluetoothUUID(android: $0.getUuid())
                let isPrimary = $0.type.isPrimary
                // cache value
                services.values[id] = $0
                // map value
                return Service(
                    id: id,
                    uuid: uuid,
                    peripheral: peripheral,
                    isPrimary: isPrimary
                )
            }
        }
        
        mutating func update(
            _ newValues: [BluetoothGattCharacteristic],
            for service: Service<Peripheral, AttributeID>
        ) -> [Characteristic<Peripheral, AttributeID>] {
            return newValues.map {
                let id = identifier(for: $0)
                let peripheral = Peripheral(gatt)
                let uuid = BluetoothUUID(android: $0.getUuid())
                let properties = CharacteristicProperties(rawValue: UInt8($0.getProperties()))
                // cache
                characteristics.values[id] = CharacteristicCache(object: $0)
                // return Swift value
                return Characteristic(
                    id: id,
                    uuid: uuid,
                    peripheral: peripheral,
                    properties: properties
                )
            }
        }
        
        mutating func update(
            _ newValues: [BluetoothGattDescriptor],
            for characteristic: Characteristic<Peripheral, AttributeID>
        ) -> [Descriptor<Peripheral, AttributeID>] {
            return newValues.map {
                let id = identifier(for: $0, characteristic: characteristic)
                let peripheral = Peripheral(gatt)
                let uuid = BluetoothUUID(android: $0.getUuid())
                // cache object
                descriptors.values[id] = $0
                // return swift value
                return Descriptor(
                    id: id,
                    uuid: uuid,
                    peripheral: peripheral
                )
            }
        }
    }
    
    struct PeripheralContinuation {
        
        var connect: CheckedContinuation<Void, Error>?
        
        var exchangeMTU: CheckedContinuation<MaximumTransmissionUnit, Error>?
        
        var discoverServices: CheckedContinuation<[Service<Peripheral, AttributeID>], Error>?
        
        var discoverCharacteristics: CheckedContinuation<[Characteristic<Peripheral, AttributeID>], Error>?
        
        var discoverDescriptors: CheckedContinuation<[Descriptor<Peripheral, AttributeID>], Error>?
        
        var readCharacteristic: CheckedContinuation<Data, Error>?
        
        var writeCharacteristic: CheckedContinuation<Void, Error>?
        
        var readDescriptor: CheckedContinuation<Data, Error>?
        
        var writeDescriptor: CheckedContinuation<Void, Error>?
        
        var readRemoteRSSI: CheckedContinuation<Int, Error>?
    }
    
    struct Services {
        
        var values: [AndroidCentral.AttributeID: BluetoothGattService] = [:]
    }
    
    struct Characteristics {
       
        var values: [AndroidCentral.AttributeID: CharacteristicCache] = [:]
    }
    
    
    struct Descriptors {
       
        var values: [AndroidCentral.AttributeID: BluetoothGattDescriptor] = [:]
    }
    
    struct CharacteristicCache {
        
        let object: BluetoothGattCharacteristic
                    
        var notification: AsyncIndefiniteStream<Data>.Continuation?
    }
}
