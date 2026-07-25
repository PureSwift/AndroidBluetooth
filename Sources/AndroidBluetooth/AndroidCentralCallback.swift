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
// each event as primitive values to the jextract-generated `AndroidBluetoothBridge`
// Java class, which resolves the central by its registry identifier and calls the
// `handle*` event methods in `AndroidCentralEvents.swift`. These wrappers exist only
// so Swift can construct the adapter instances to hand to the Android APIs.

extension AndroidCentral {

    @JavaClass("org.pureswift.bluetooth.le.ScanCallback")
    internal class LowEnergyScanCallback: AndroidBluetooth.ScanCallback {

        @JavaMethod
        @_nonoverride convenience init(centralId: Int64, environment: JNIEnvironment? = nil)

        convenience init(central: AndroidCentral, environment: JNIEnvironment? = nil) {
            self.init(centralId: central.identifier, environment: environment)
        }
    }
}

extension AndroidCentral {

    @JavaClass("org.pureswift.bluetooth.BluetoothGattCallback")
    class GattCallback: AndroidBluetooth.BluetoothGattCallback {

        @JavaMethod
        @_nonoverride convenience init(centralId: Int64, peripheralAddress: String, environment: JNIEnvironment? = nil)

        convenience init(central: AndroidCentral, peripheral: Peripheral, environment: JNIEnvironment? = nil) {
            self.init(centralId: central.identifier, peripheralAddress: peripheral.address, environment: environment)
        }
    }
}
