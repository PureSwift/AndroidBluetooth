//
//  AndroidCentralHandoff.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/25/26.
//

import Synchronization
import Bluetooth
import GATT

/// Hands an ``AndroidCentral`` (and target peripheral) to the bridge target while a
/// Kotlin callback adapter is being constructed.
///
/// The Kotlin adapters obtain their Swift event handler in their constructor by calling
/// a jextract-generated static, which runs on the same thread inside the adapter's
/// Swift `init` call. This type carries the central across that synchronous window:
/// ``withPending(central:peripheral:_:)`` publishes the pending value, runs the
/// constructor, and clears the slot — serialized so concurrent constructions can't
/// observe each other's value. Nothing is retained beyond the construction call.
@available(Android 18, *)
package enum AndroidCentralHandoff {

    private struct Pending {
        weak var central: AndroidCentral?
        var peripheral: Peripheral?
    }

    private static let slot = Mutex<Pending?>(nil)

    /// Serializes set-construct-take sequences. Separate from `slot` because the
    /// take happens via JNI re-entrancy on the same thread while this lock is held.
    private static let constructionLock = Mutex<Void>(())

    /// Publish `central` (and optionally the target peripheral) for the duration of
    /// `construct`, which must synchronously trigger the bridge's take call.
    package static func withPending<T>(
        central: AndroidCentral,
        peripheral: Peripheral? = nil,
        _ construct: () -> T
    ) -> T {
        constructionLock.withLock { _ in
            slot.withLock { $0 = Pending(central: central, peripheral: peripheral) }
            defer { slot.withLock { $0 = nil } }
            return construct()
        }
    }

    /// Consume the pending central. Called (indirectly, over JNI) from the Kotlin
    /// adapter constructor running inside ``withPending(central:peripheral:_:)``.
    package static func takePending() -> (central: AndroidCentral, peripheral: Peripheral?)? {
        slot.withLock { pending in
            defer { pending = nil }
            guard let value = pending, let central = value.central else {
                return nil
            }
            return (central, value.peripheral)
        }
    }
}
