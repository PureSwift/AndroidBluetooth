//
//  BluetoothDemoBridge.swift
//  SwiftAndroidApp
//
//  Created by Alsey Coleman Miller on 7/25/26.
//
//  Public jextract surface for the demo app's Compose UI.
//
//  This target is processed by the swift-java `JExtractSwiftPlugin` (JNI mode with
//  Java callbacks, see `swift-java.config`), which generates the
//  `com.pureswift.swiftandroid.bridge.BluetoothDemoBridge` Java class. Kotlin calls
//  the static methods below, passing lambdas for the closure parameters; Swift invokes
//  those lambdas as Bluetooth events arrive. Only jextract-supported types
//  (primitives, String, closures) may appear in public declarations here; the
//  implementation lives in `DemoCentral.swift` using internal visibility.

/// Start scanning for BLE peripherals.
///
/// - Parameter onScanResult: Invoked for every advertisement received, with the
///   peripheral's address, advertised name (empty if none), and RSSI.
///   Called from a background thread.
public func startScan(
    onScanResult: @escaping (String, String, Int64) -> Void
) {
    DemoCentral.shared.startScan(onScanResult: onScanResult)
}

/// Stop an ongoing scan.
public func stopScan() {
    DemoCentral.shared.stopScan()
}

/// Connect to a previously scanned peripheral and discover its services.
///
/// - Parameters:
///   - address: The peripheral's Bluetooth address (from ``startScan``).
///   - onConnected: Invoked when the connection is established.
///   - onServiceDiscovered: Invoked once per discovered service with its UUID string.
///   - onError: Invoked with a description if connecting or discovery fails.
///   All callbacks are invoked from a background thread.
public func connect(
    address: String,
    onConnected: @escaping () -> Void,
    onServiceDiscovered: @escaping (String) -> Void,
    onError: @escaping (String) -> Void
) {
    DemoCentral.shared.connect(
        address: address,
        onConnected: onConnected,
        onServiceDiscovered: onServiceDiscovered,
        onError: onError
    )
}

/// Disconnect from a peripheral.
public func disconnect(address: String) {
    DemoCentral.shared.disconnect(address: address)
}
