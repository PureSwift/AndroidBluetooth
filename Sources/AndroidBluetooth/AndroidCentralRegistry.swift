//
//  AndroidCentralRegistry.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/25/26.
//

import Synchronization

/// Maps stable `Int64` identifiers to live ``AndroidCentral`` instances.
///
/// Kotlin callback adapters are constructed with a central's identifier and pass it
/// back through the JNI bridge with every event; the bridge resolves it here.
/// Entries are weak so the registry never extends a central's lifetime.
@available(Android 18, *)
package enum AndroidCentralRegistry {

    private struct WeakBox {
        weak var central: AndroidCentral?
    }

    private static let storage = Mutex<(nextID: Int64, values: [Int64: WeakBox])>((nextID: 1, values: [:]))

    /// Reserve a unique identifier for a central that is being initialized.
    package static func reserveIdentifier() -> Int64 {
        storage.withLock { state in
            let id = state.nextID
            state.nextID += 1
            return id
        }
    }

    /// Register a central under a previously reserved identifier.
    package static func register(_ central: AndroidCentral, for id: Int64) {
        storage.withLock { state in
            state.values[id] = WeakBox(central: central)
        }
    }

    /// Remove a central from the registry.
    package static func unregister(_ id: Int64) {
        storage.withLock { state in
            state.values[id] = nil
        }
    }

    /// Resolve a central from an identifier received over JNI.
    package static func central(for id: Int64) -> AndroidCentral? {
        storage.withLock { state in
            state.values[id]?.central
        }
    }
}
