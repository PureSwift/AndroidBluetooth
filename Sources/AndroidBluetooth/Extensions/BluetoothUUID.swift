//
//  BluetoothUUID.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import JavaUtil
import JavaLangUtil
import Bluetooth

internal extension BluetoothUUID {
    
    init(android javaUUID: JavaLangUtil.UUID) {
        
        let uuid = UUID(uuidString: javaUUID.toString())!
        if let value = UInt16(bluetooth: uuid) {
            self = .bit16(value)
        } else {
            self = .bit128(UInt128(uuid: uuid))
        }
    }
}
