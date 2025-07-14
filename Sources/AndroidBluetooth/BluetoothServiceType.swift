//
//  AndroidBluetoothServiceType.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

import JavaKit

/// Bluetooth Service Type
public enum AndroidBluetoothServiceType: Equatable, Hashable, Sendable, CaseIterable {
    
    /**
     * Primary service.
     */
    case primary
    
    /**
     * Secondary service (included by primary services).
     */
    case secondary
}

public extension AndroidBluetoothServiceType {
    
    init(isPrimary: Bool) {
        self = isPrimary ? .primary : .secondary
    }
    
    var isPrimary: Bool {
        switch self {
        case .primary:
            true
        case .secondary:
            false
        }
    }
}

// MARK: - RawRepresentable

extension AndroidBluetoothServiceType: RawRepresentable {
    
    public init?(rawValue: Int32) {
        guard let value = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self = value
    }
    
    public var rawValue: Int32 {
        switch self {
        case .primary:
            Self.javaClass.SERVICE_TYPE_PRIMARY
        case .secondary:
            Self.javaClass.SERVICE_TYPE_SECONDARY
        }
    }
}

public extension BluetoothGattService {
    
    typealias ServiceType = AndroidBluetoothServiceType
}

internal extension AndroidBluetoothServiceType {
    
    static let javaClass = try! JavaClass<BluetoothGattService>()
}
