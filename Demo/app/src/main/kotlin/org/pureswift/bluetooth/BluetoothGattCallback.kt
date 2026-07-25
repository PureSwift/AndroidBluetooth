package org.pureswift.bluetooth

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback as AndroidGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import org.pureswift.bluetooth.bridge.AndroidBluetoothBridge

/**
 * Bluetooth GATT Callback for the AndroidBluetooth Swift package.
 *
 * This class is instantiated by AndroidBluetooth's `GattCallback`
 * via the `@JavaClass("org.pureswift.bluetooth.BluetoothGattCallback")` annotation.
 * It extends Android's `BluetoothGattCallback` and forwards each event as primitive
 * values to the jextract-generated [AndroidBluetoothBridge], keyed by the Swift
 * central's registry identifier and the peripheral's address.
 */
open class BluetoothGattCallback(
    private val centralId: Long,
    private val peripheralAddress: String
) : AndroidGattCallback() {

    override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
        super.onConnectionStateChange(gatt, status, newState)
        AndroidBluetoothBridge.gattCallbackOnConnectionStateChange(centralId, peripheralAddress, status, newState)
    }

    override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
        super.onServicesDiscovered(gatt, status)
        AndroidBluetoothBridge.gattCallbackOnServicesDiscovered(centralId, peripheralAddress, status)
    }

    @Deprecated("Deprecated in Java")
    override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
        @Suppress("DEPRECATION")
        super.onCharacteristicChanged(gatt, characteristic)
        AndroidBluetoothBridge.gattCallbackOnCharacteristicChanged(
            centralId,
            peripheralAddress,
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
        AndroidBluetoothBridge.gattCallbackOnCharacteristicRead(
            centralId,
            peripheralAddress,
            characteristic.uuid.toString(),
            characteristic.instanceId,
            @Suppress("DEPRECATION")
            characteristic.value ?: ByteArray(0),
            status
        )
    }

    override fun onCharacteristicWrite(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic?, status: Int) {
        super.onCharacteristicWrite(gatt, characteristic, status)
        AndroidBluetoothBridge.gattCallbackOnCharacteristicWrite(
            centralId,
            peripheralAddress,
            characteristic?.uuid?.toString() ?: "",
            characteristic?.instanceId ?: 0,
            status
        )
    }

    @Deprecated("Deprecated in Java")
    override fun onDescriptorRead(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
        @Suppress("DEPRECATION")
        super.onDescriptorRead(gatt, descriptor, status)
        AndroidBluetoothBridge.gattCallbackOnDescriptorRead(
            centralId,
            peripheralAddress,
            descriptor.uuid.toString(),
            @Suppress("DEPRECATION")
            descriptor.value ?: ByteArray(0),
            status
        )
    }

    override fun onDescriptorWrite(gatt: BluetoothGatt?, descriptor: BluetoothGattDescriptor?, status: Int) {
        super.onDescriptorWrite(gatt, descriptor, status)
        AndroidBluetoothBridge.gattCallbackOnDescriptorWrite(
            centralId,
            peripheralAddress,
            descriptor?.uuid?.toString() ?: "",
            status
        )
    }

    override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
        super.onMtuChanged(gatt, mtu, status)
        AndroidBluetoothBridge.gattCallbackOnMtuChanged(centralId, peripheralAddress, mtu, status)
    }

    override fun onPhyRead(gatt: BluetoothGatt?, txPhy: Int, rxPhy: Int, status: Int) {
        super.onPhyRead(gatt, txPhy, rxPhy, status)
        AndroidBluetoothBridge.gattCallbackOnPhyRead(centralId, peripheralAddress, txPhy, rxPhy, status)
    }

    override fun onPhyUpdate(gatt: BluetoothGatt?, txPhy: Int, rxPhy: Int, status: Int) {
        super.onPhyUpdate(gatt, txPhy, rxPhy, status)
        AndroidBluetoothBridge.gattCallbackOnPhyUpdate(centralId, peripheralAddress, txPhy, rxPhy, status)
    }

    override fun onReadRemoteRssi(gatt: BluetoothGatt?, rssi: Int, status: Int) {
        super.onReadRemoteRssi(gatt, rssi, status)
        AndroidBluetoothBridge.gattCallbackOnReadRemoteRssi(centralId, peripheralAddress, rssi, status)
    }

    override fun onReliableWriteCompleted(gatt: BluetoothGatt?, status: Int) {
        super.onReliableWriteCompleted(gatt, status)
        AndroidBluetoothBridge.gattCallbackOnReliableWriteCompleted(centralId, peripheralAddress, status)
    }
}
