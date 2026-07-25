//
//  AndroidBluetoothBridge.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/25/26.
//
//  JNI entry points for the Kotlin Bluetooth callback adapters.
//
//  This target is processed by the swift-java `JExtractSwiftPlugin` (JNI mode, see
//  `swift-java.config`), which generates the `org.pureswift.bluetooth.bridge.AndroidBluetoothBridge`
//  Java class with a static method per public function below. The Kotlin adapter classes
//  (`org.pureswift.bluetooth.le.ScanCallback` and `org.pureswift.bluetooth.BluetoothGattCallback`)
//  extend the Android framework callback classes and forward each event here as primitive
//  values, keyed by the central's registry identifier (and peripheral address for GATT).
//
//  Only jextract-supported types (primitives, String, primitive arrays) may appear in public
//  declarations in this target.

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import AndroidBluetooth

// MARK: - Scan Callback Events

public func scanCallbackOnScanResult(
    centralId: Int64,
    callbackType: Int32,
    address: String,
    rssi: Int32,
    isConnectable: Bool,
    advertisementData: [UInt8]
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleScanResult(
        callbackType: callbackType,
        address: address,
        rssi: rssi,
        isConnectable: isConnectable,
        advertisementData: Data(advertisementData)
    )
}

public func scanCallbackOnScanFailed(
    centralId: Int64,
    errorCode: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleScanFailed(errorCode: errorCode)
}

// MARK: - GATT Callback Events

public func gattCallbackOnConnectionStateChange(
    centralId: Int64,
    peripheralAddress: String,
    status: Int32,
    newState: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleConnectionStateChange(
        address: peripheralAddress,
        status: status,
        newState: newState
    )
}

public func gattCallbackOnServicesDiscovered(
    centralId: Int64,
    peripheralAddress: String,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleServicesDiscovered(
        address: peripheralAddress,
        status: status
    )
}

public func gattCallbackOnCharacteristicChanged(
    centralId: Int64,
    peripheralAddress: String,
    characteristicUuid: String,
    characteristicInstanceId: Int32,
    value: [UInt8]
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleCharacteristicChanged(
        address: peripheralAddress,
        uuid: characteristicUuid,
        instanceID: characteristicInstanceId,
        value: Data(value)
    )
}

public func gattCallbackOnCharacteristicRead(
    centralId: Int64,
    peripheralAddress: String,
    characteristicUuid: String,
    characteristicInstanceId: Int32,
    value: [UInt8],
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleCharacteristicRead(
        address: peripheralAddress,
        uuid: characteristicUuid,
        instanceID: characteristicInstanceId,
        value: Data(value),
        status: status
    )
}

public func gattCallbackOnCharacteristicWrite(
    centralId: Int64,
    peripheralAddress: String,
    characteristicUuid: String,
    characteristicInstanceId: Int32,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleCharacteristicWrite(
        address: peripheralAddress,
        uuid: characteristicUuid,
        instanceID: characteristicInstanceId,
        status: status
    )
}

public func gattCallbackOnDescriptorRead(
    centralId: Int64,
    peripheralAddress: String,
    descriptorUuid: String,
    value: [UInt8],
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleDescriptorRead(
        address: peripheralAddress,
        uuid: descriptorUuid,
        value: Data(value),
        status: status
    )
}

public func gattCallbackOnDescriptorWrite(
    centralId: Int64,
    peripheralAddress: String,
    descriptorUuid: String,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleDescriptorWrite(
        address: peripheralAddress,
        uuid: descriptorUuid,
        status: status
    )
}

public func gattCallbackOnMtuChanged(
    centralId: Int64,
    peripheralAddress: String,
    mtu: Int32,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleMtuChanged(
        address: peripheralAddress,
        mtu: mtu,
        status: status
    )
}

public func gattCallbackOnPhyRead(
    centralId: Int64,
    peripheralAddress: String,
    txPhy: Int32,
    rxPhy: Int32,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handlePhyRead(
        address: peripheralAddress,
        txPhy: txPhy,
        rxPhy: rxPhy,
        status: status
    )
}

public func gattCallbackOnPhyUpdate(
    centralId: Int64,
    peripheralAddress: String,
    txPhy: Int32,
    rxPhy: Int32,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handlePhyUpdate(
        address: peripheralAddress,
        txPhy: txPhy,
        rxPhy: rxPhy,
        status: status
    )
}

public func gattCallbackOnReadRemoteRssi(
    centralId: Int64,
    peripheralAddress: String,
    rssi: Int32,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleReadRemoteRssi(
        address: peripheralAddress,
        rssi: rssi,
        status: status
    )
}

public func gattCallbackOnReliableWriteCompleted(
    centralId: Int64,
    peripheralAddress: String,
    status: Int32
) {
    guard let central = AndroidCentralRegistry.central(for: centralId) else { return }
    central.handleReliableWriteCompleted(
        address: peripheralAddress,
        status: status
    )
}
