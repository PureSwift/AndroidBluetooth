//
//  AndroidCentralCallback.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import SwiftJava
import JavaUtil
import JavaLangUtil
import Bluetooth
import GATT

// MARK: - Callback Adapters
//
// The Kotlin adapter classes extend the Android framework callback classes and forward
// each event to a Swift-implemented event handler (`BluetoothScanEventHandler` /
// `BluetoothGattEventHandler`, jextract-generated Java interfaces from the
// AndroidBluetoothBridge target). The adapters obtain their handler in their
// no-argument constructor, which runs inside `AndroidCentralHandoff.withPending`,
// so construction must go through the `create` factories below.

extension AndroidCentral {

    @JavaClass("org.pureswift.bluetooth.le.ScanCallback")
    internal class LowEnergyScanCallback: AndroidBluetooth.ScanCallback {

        @JavaMethod
        @_nonoverride convenience init(environment: JNIEnvironment? = nil)
    }
}

extension AndroidCentral.LowEnergyScanCallback {

    static func create(central: AndroidCentral) -> AndroidCentral.LowEnergyScanCallback {
        AndroidCentralHandoff.withPending(central: central) {
            AndroidCentral.LowEnergyScanCallback()
        }
    }
}

extension AndroidCentral {

    @JavaClass("org.pureswift.bluetooth.BluetoothGattCallback")
    class GattCallback: AndroidBluetooth.BluetoothGattCallback {

        @JavaMethod
        @_nonoverride convenience init(environment: JNIEnvironment? = nil)
    }
}

extension AndroidCentral.GattCallback {

    static func create(central: AndroidCentral, peripheral: Peripheral) -> AndroidCentral.GattCallback {
        AndroidCentralHandoff.withPending(central: central, peripheral: peripheral) {
            AndroidCentral.GattCallback()
        }
    }
}
