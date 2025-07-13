//
//  Peripheral.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

import Bluetooth
import GATT

internal extension Peripheral {
    
    init(_ device: AndroidBluetooth.BluetoothDevice) {
        self.init(id: device.address)
    }
    
    init(_ gatt: AndroidBluetooth.BluetoothGatt) {
        self.init(gatt.getDevice())
    }
}
