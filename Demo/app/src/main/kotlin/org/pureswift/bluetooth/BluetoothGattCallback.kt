package org.pureswift.bluetooth

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback as AndroidGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import org.pureswift.bluetooth.bridge.AndroidBluetoothBridge
import org.pureswift.bluetooth.bridge.BluetoothGattEventSink
import org.swift.swiftkit.core.SwiftArena

/**
 * Bluetooth GATT Callback for the AndroidBluetooth Swift package.
 *
 * This class is instantiated by AndroidBluetooth's `GattCallback`
 * via the `@JavaClass("org.pureswift.bluetooth.BluetoothGattCallback")` annotation.
 * It extends Android's `BluetoothGattCallback` and forwards each event to a
 * [BluetoothGattEventSink] — a Swift-implemented sink surfaced through the
 * jextract-generated class, created for a specific central and peripheral.
 * The no-argument constructor obtains the sink for the connection currently
 * under construction.
 */
open class BluetoothGattCallback(
    private val sink: BluetoothGattEventSink
) : AndroidGattCallback() {

    constructor() : this(AndroidBluetoothBridge.takePendingGattEventSink(SwiftArena.ofAuto()))

    override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
        super.onConnectionStateChange(gatt, status, newState)
        sink.onConnectionStateChange(status, newState)
    }

    override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
        super.onServicesDiscovered(gatt, status)
        sink.onServicesDiscovered(status)
    }

    @Deprecated("Deprecated in Java")
    override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
        @Suppress("DEPRECATION")
        super.onCharacteristicChanged(gatt, characteristic)
        sink.onCharacteristicChanged(
            characteristic.uuid.toString(),
            characteristic.instanceId,
            @Suppress("DEPRECATION")
            characteristic.value ?: ByteArray(0)
        )
    }

    @Deprecated("Deprecated in Java")
    override fun onCharacteristicRead(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
        @Suppress("DEPRECATION")
        super.onCharacteristicRead(gatt, characteristic, status)
        sink.onCharacteristicRead(
            characteristic.uuid.toString(),
            characteristic.instanceId,
            @Suppress("DEPRECATION")
            characteristic.value ?: ByteArray(0),
            status
        )
    }

    override fun onCharacteristicWrite(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic?, status: Int) {
        super.onCharacteristicWrite(gatt, characteristic, status)
        sink.onCharacteristicWrite(
            characteristic?.uuid?.toString() ?: "",
            characteristic?.instanceId ?: 0,
            status
        )
    }

    @Deprecated("Deprecated in Java")
    override fun onDescriptorRead(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
        @Suppress("DEPRECATION")
        super.onDescriptorRead(gatt, descriptor, status)
        sink.onDescriptorRead(
            descriptor.uuid.toString(),
            @Suppress("DEPRECATION")
            descriptor.value ?: ByteArray(0),
            status
        )
    }

    override fun onDescriptorWrite(gatt: BluetoothGatt?, descriptor: BluetoothGattDescriptor?, status: Int) {
        super.onDescriptorWrite(gatt, descriptor, status)
        sink.onDescriptorWrite(descriptor?.uuid?.toString() ?: "", status)
    }

    override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
        super.onMtuChanged(gatt, mtu, status)
        sink.onMtuChanged(mtu, status)
    }

    override fun onPhyRead(gatt: BluetoothGatt?, txPhy: Int, rxPhy: Int, status: Int) {
        super.onPhyRead(gatt, txPhy, rxPhy, status)
        sink.onPhyRead(txPhy, rxPhy, status)
    }

    override fun onPhyUpdate(gatt: BluetoothGatt?, txPhy: Int, rxPhy: Int, status: Int) {
        super.onPhyUpdate(gatt, txPhy, rxPhy, status)
        sink.onPhyUpdate(txPhy, rxPhy, status)
    }

    override fun onReadRemoteRssi(gatt: BluetoothGatt?, rssi: Int, status: Int) {
        super.onReadRemoteRssi(gatt, rssi, status)
        sink.onReadRemoteRssi(rssi, status)
    }

    override fun onReliableWriteCompleted(gatt: BluetoothGatt?, status: Int) {
        super.onReliableWriteCompleted(gatt, status)
        sink.onReliableWriteCompleted(status)
    }
}
