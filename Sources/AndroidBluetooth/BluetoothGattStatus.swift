//
//  BluetoothGattStatus.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

import SwiftJava

public extension BluetoothGatt {
    
    /// Bluetooth Gatt Status
    struct Status: RawRepresentable, Equatable, Hashable, Sendable {
        
        public let rawValue: Int32
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        private init(_ raw: Int32) {
            self.init(rawValue: raw)
        }
    }
}

internal extension BluetoothGatt.Status {
    
    static let javaClass = try! JavaClass<BluetoothGatt>()
}

public extension BluetoothGatt.Status {
    
    /**
     * A remote device connection is congested.
     */
    static let connectionCongested = BluetoothGatt.Status(javaClass.GATT_CONNECTION_CONGESTED)
    
    /**
     * A GATT operation failed, errors other than the above
     */
    static let failure = BluetoothGatt.Status(javaClass.GATT_FAILURE)
    
    /**
     * Insufficient authentication for a given operation
     */
    static let insufficientAuthentication = BluetoothGatt.Status(javaClass.GATT_INSUFFICIENT_AUTHENTICATION)
    
    /**
     * Insufficient encryption for a given operation
     */
    static let insufficientEncryption = BluetoothGatt.Status(javaClass.GATT_INSUFFICIENT_ENCRYPTION)
    
    /**
     * A write operation exceeds the maximum length of the attribute
     */
    static let invalidAttibuteLength = BluetoothGatt.Status(javaClass.GATT_INVALID_ATTRIBUTE_LENGTH)
    
    /**
     * A read or write operation was requested with an invalid offset
     */
    static let invalidOffset = BluetoothGatt.Status(javaClass.GATT_INVALID_OFFSET)
    
    /**
     * GATT read operation is not permitted
     */
    static let readNotPermitted = BluetoothGatt.Status(javaClass.GATT_READ_NOT_PERMITTED)
    
    /**
     * The given request is not supported
     */
    static let requestNotSupported = BluetoothGatt.Status(javaClass.GATT_REQUEST_NOT_SUPPORTED)
    
    /**
     * A GATT operation completed successfully
     */
    static let success = BluetoothGatt.Status(javaClass.GATT_SUCCESS)
    
    /**
     * GATT write operation is not permitted
     */
    static let writeNotPermitted = BluetoothGatt.Status(javaClass.GATT_WRITE_NOT_PERMITTED)
}
