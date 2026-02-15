//
//  BluetoothConnectionState.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

import SwiftJava

/// Connection State
public enum BluetoothConnectionState: Equatable, Hashable, Sendable, CaseIterable {
    
    /// The profile is in connected state
    case connected
    
    case connecting
    
    case disconnecting
    
    case disconnected
}

internal extension BluetoothConnectionState {
    
    static let javaClass = try! JavaClass<BluetoothProfile>()
}

// MARK: - RawRepresentable

extension BluetoothConnectionState: RawRepresentable {
    
    public init?(rawValue: Int32) {
        guard let value = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self = value
    }
    
    public var rawValue: Int32 {
        switch self {
        case .connected:
            Self.javaClass.STATE_CONNECTED
        case .connecting:
            Self.javaClass.STATE_CONNECTING
        case .disconnecting:
            Self.javaClass.STATE_DISCONNECTING
        case .disconnected:
            Self.javaClass.STATE_DISCONNECTED
        }
    }
}
