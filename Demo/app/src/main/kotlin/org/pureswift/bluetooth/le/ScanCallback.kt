package org.pureswift.bluetooth.le

import android.bluetooth.le.ScanCallback as AndroidScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.os.Build
import android.util.Log
import org.pureswift.bluetooth.bridge.AndroidBluetoothBridge

/**
 * Bluetooth LE Scan Callback for the AndroidBluetooth Swift package.
 *
 * This class is instantiated by AndroidBluetooth's `LowEnergyScanCallback`
 * via the `@JavaClass("org.pureswift.bluetooth.le.ScanCallback")` annotation.
 * It extends Android's `ScanCallback` and forwards each event as primitive values
 * to the jextract-generated [AndroidBluetoothBridge], keyed by the Swift central's
 * registry identifier.
 */
open class ScanCallback(
    private val centralId: Long
) : AndroidScanCallback() {

    companion object {
        private const val TAG = "PureSwift.ScanCallback"
    }

    /**
     * Callback when a BLE advertisement has been found.
     *
     * @param callbackType Determines how this callback was triggered
     * @param result A Bluetooth LE scan result
     */
    override fun onScanResult(callbackType: Int, result: ScanResult?) {
        super.onScanResult(callbackType, result)
        result?.let { forward(callbackType, it) }
    }

    /**
     * Callback when batch results are delivered.
     *
     * @param results List of scan results that are previously scanned
     */
    override fun onBatchScanResults(results: MutableList<ScanResult>?) {
        super.onBatchScanResults(results)
        results?.forEach { forward(ScanSettings.CALLBACK_TYPE_ALL_MATCHES, it) }
    }

    /**
     * Callback when scan could not be started.
     *
     * @param errorCode Error code (one of SCAN_FAILED_*)
     */
    override fun onScanFailed(errorCode: Int) {
        super.onScanFailed(errorCode)
        Log.e(TAG, "onScanFailed: errorCode=$errorCode")
        AndroidBluetoothBridge.scanCallbackOnScanFailed(centralId, errorCode)
    }

    private fun forward(callbackType: Int, result: ScanResult) {
        val isConnectable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            result.isConnectable
        } else {
            true
        }
        AndroidBluetoothBridge.scanCallbackOnScanResult(
            centralId,
            callbackType,
            result.device.address,
            result.rssi,
            isConnectable,
            result.scanRecord?.bytes ?: ByteArray(0)
        )
    }
}
