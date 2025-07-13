//
//  BluetoothTransport.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/12/25.
//

/// Preferred transport for GATT connections to remote dual-mode devices
public enum BluetoothTransport: Int32, Sendable, CaseIterable {
    
    /// No preference of physical transport for GATT connections to remote dual-mode devices
    case auto   = 0
    
    /// Constant representing the BR/EDR transport.
    case bredr  = 1
    
    /// Constant representing the Bluetooth Low Energy (BLE) Transport.
    case le     = 2
}
