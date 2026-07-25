//
//  BluetoothEventSink.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/25/26.
//
//  Swift classes receiving the Bluetooth callback events. jextract exposes each as a
//  Java class with native instance methods, so the Kotlin callback adapters hold and
//  invoke a Swift instance directly — no identifier registry needed. Instances are
//  created through the `takePending*` factories below, which run inside
//  `AndroidCentralHandoff.withPending` during adapter construction.

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import AndroidBluetooth

// MARK: - Factories

/// Create the scan event sink for the ``AndroidCentral`` currently under construction.
/// Called by the Kotlin `ScanCallback` constructor, which runs inside
/// `AndroidCentralHandoff.withPending` on the Swift side.
public func takePendingScanEventSink() -> BluetoothScanEventSink {
    guard let pending = AndroidCentralHandoff.takePending() else {
        fatalError("ScanCallback constructed outside of AndroidCentralHandoff.withPending")
    }
    return BluetoothScanEventSink(central: pending.central)
}

/// Create the GATT event sink for the ``AndroidCentral`` and peripheral currently
/// under construction. Called by the Kotlin `BluetoothGattCallback` constructor, which
/// runs inside `AndroidCentralHandoff.withPending` on the Swift side.
public func takePendingGattEventSink() -> BluetoothGattEventSink {
    guard let pending = AndroidCentralHandoff.takePending(), let peripheral = pending.peripheral else {
        fatalError("BluetoothGattCallback constructed outside of AndroidCentralHandoff.withPending")
    }
    return BluetoothGattEventSink(central: pending.central, address: peripheral.address)
}

// MARK: - Scan Events

/// Receives Bluetooth LE scan events for an ``AndroidCentral``.
///
/// jextract surfaces this as the `org.pureswift.bluetooth.bridge.BluetoothScanEventSink`
/// Java class; the Kotlin `ScanCallback` adapter holds one and forwards every Android
/// scan callback to it.
public final class BluetoothScanEventSink {

    private weak var central: AndroidCentral?

    internal init(central: AndroidCentral?) {
        self.central = central
    }

    public func onScanResult(
        callbackType: Int32,
        address: String,
        rssi: Int32,
        isConnectable: Bool,
        advertisementData: [UInt8]
    ) {
        central?.handleScanResult(
            callbackType: callbackType,
            address: address,
            rssi: rssi,
            isConnectable: isConnectable,
            advertisementData: Data(advertisementData)
        )
    }

    public func onScanFailed(errorCode: Int32) {
        central?.handleScanFailed(errorCode: errorCode)
    }
}

// MARK: - GATT Events

/// Receives GATT events for a single peripheral connection of an ``AndroidCentral``.
///
/// jextract surfaces this as the `org.pureswift.bluetooth.bridge.BluetoothGattEventSink`
/// Java class; the Kotlin `BluetoothGattCallback` adapter holds one and forwards every
/// Android GATT callback to it. The sink is created for a specific peripheral, so
/// events carry no address.
public final class BluetoothGattEventSink {

    private weak var central: AndroidCentral?

    private let address: String

    internal init(central: AndroidCentral?, address: String) {
        self.central = central
        self.address = address
    }

    public func onConnectionStateChange(status: Int32, newState: Int32) {
        central?.handleConnectionStateChange(address: address, status: status, newState: newState)
    }

    public func onServicesDiscovered(status: Int32) {
        central?.handleServicesDiscovered(address: address, status: status)
    }

    public func onCharacteristicChanged(uuid: String, instanceId: Int32, value: [UInt8]) {
        central?.handleCharacteristicChanged(address: address, uuid: uuid, instanceID: instanceId, value: Data(value))
    }

    public func onCharacteristicRead(uuid: String, instanceId: Int32, value: [UInt8], status: Int32) {
        central?.handleCharacteristicRead(address: address, uuid: uuid, instanceID: instanceId, value: Data(value), status: status)
    }

    public func onCharacteristicWrite(uuid: String, instanceId: Int32, status: Int32) {
        central?.handleCharacteristicWrite(address: address, uuid: uuid, instanceID: instanceId, status: status)
    }

    public func onDescriptorRead(uuid: String, value: [UInt8], status: Int32) {
        central?.handleDescriptorRead(address: address, uuid: uuid, value: Data(value), status: status)
    }

    public func onDescriptorWrite(uuid: String, status: Int32) {
        central?.handleDescriptorWrite(address: address, uuid: uuid, status: status)
    }

    public func onMtuChanged(mtu: Int32, status: Int32) {
        central?.handleMtuChanged(address: address, mtu: mtu, status: status)
    }

    public func onPhyRead(txPhy: Int32, rxPhy: Int32, status: Int32) {
        central?.handlePhyRead(address: address, txPhy: txPhy, rxPhy: rxPhy, status: status)
    }

    public func onPhyUpdate(txPhy: Int32, rxPhy: Int32, status: Int32) {
        central?.handlePhyUpdate(address: address, txPhy: txPhy, rxPhy: rxPhy, status: status)
    }

    public func onReadRemoteRssi(rssi: Int32, status: Int32) {
        central?.handleReadRemoteRssi(address: address, rssi: rssi, status: status)
    }

    public func onReliableWriteCompleted(status: Int32) {
        central?.handleReliableWriteCompleted(address: address, status: status)
    }
}
