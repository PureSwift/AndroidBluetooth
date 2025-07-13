//
//  AndroidCentralError.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

/// Android Central Error
public enum AndroidCentralError: Swift.Error {
    
    /// Bluetooth is disabled.
    case bluetoothDisabled
    
    /// Binder IPC failure.
    case binderFailure
    
    /// Unexpected null value.
    case nullValue(AnyKeyPath)
    
    case scanFailed(Int32)
    
    
}
