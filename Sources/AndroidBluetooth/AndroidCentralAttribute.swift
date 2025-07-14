//
//  AndroidCentralAttribute.swift
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

internal protocol AndroidCentralAttribute {
    
    static var attributeType: AndroidCentralAttributeType { get }
    
    func getInstanceId() -> Int32
    
    func getUuid() -> JavaUtil.UUID!
}

enum AndroidCentralAttributeType: String, Sendable, CaseIterable {
    
    case service = "Service"
    
    case characteristic = "Characteristic"
}

extension BluetoothGattService: AndroidCentralAttribute {
    
    static var attributeType: AndroidCentralAttributeType { .service }
}

extension BluetoothGattCharacteristic: AndroidCentralAttribute {
    
    static var attributeType: AndroidCentralAttributeType { .characteristic }
}
