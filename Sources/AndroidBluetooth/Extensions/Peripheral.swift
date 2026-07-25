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

    /// Initialize from a Bluetooth address string (e.g. `"00:11:22:AA:BB:CC"`).
    init?(address: String) {
        guard let address = BluetoothAddress(rawValue: address) else {
            return nil
        }
        self.init(id: address)
    }

    /// The peripheral's address formatted for the Android APIs.
    var address: String {
        id.rawValue
    }
    
    init(_ gatt: AndroidBluetooth.BluetoothGatt) {
        self.init(gatt.getDevice())
    }
}
