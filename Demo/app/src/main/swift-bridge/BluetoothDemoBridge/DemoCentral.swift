//
//  DemoCentral.swift
//  SwiftAndroidApp
//
//  Created by Alsey Coleman Miller on 7/25/26.
//
//  Internal implementation behind the jextract surface in `BluetoothDemoBridge.swift`.
//  Owns the `AndroidCentral` instance, bootstrapping it from the application context
//  provided by the AndroidContext module.

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import SwiftJava
import AndroidKit
import AndroidBluetooth
import AndroidContext
import Bluetooth
import GATT

internal final class DemoCentral: @unchecked Sendable {

    static let shared = DemoCentral()

    private let central: AndroidCentral?

    private var scanTask: Task<Void, Never>?

    private init() {
        guard let application = try? AndroidContext.application,
              let environment = try? JavaVirtualMachine.shared().environment(),
              let hostController = try? JavaClass<BluetoothAdapter>().getDefaultAdapter() else {
            Self.log("Unable to initialize Bluetooth central")
            self.central = nil
            return
        }
        // The global application context, bootstrapped through
        // `ActivityThread.currentApplication()` by the AndroidContext module and
        // wrapped as a SwiftJava `Context` for use with the SDK wrappers.
        let context = AndroidContent.Context(
            javaHolder: JavaObjectHolder(
                object: application.pointer,
                environment: environment
            )
        )
        let central = AndroidCentral(
            hostController: hostController,
            context: context
        )
        central.log = { message in
            Self.log(message)
        }
        self.central = central
    }

    func startScan(onScanResult: @escaping (String, String, Int64) -> Void) {
        stopScan()
        guard let central else {
            Self.log("Bluetooth unavailable")
            return
        }
        scanTask = Task {
            do {
                Self.log("Start scan")
                let stream = try await central.scan()
                for try await scanData in stream {
                    let name = scanData.advertisementData.localName ?? ""
                    onScanResult(scanData.peripheral.id.rawValue, name, Int64(scanData.rssi))
                }
            }
            catch is CancellationError {
                Self.log("Scan stopped")
            }
            catch {
                Self.log("Scan error: \(error)")
            }
        }
    }

    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
    }

    func connect(
        address: String,
        onConnected: @escaping () -> Void,
        onServiceDiscovered: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        guard let central, let peripheral = peripheral(for: address) else {
            onError("Invalid peripheral \(address)")
            return
        }
        Task {
            do {
                Self.log("Connecting to \(address)")
                try await central.connect(to: peripheral)
                onConnected()
                let services = try await central.discoverServices([], for: peripheral)
                for service in services {
                    onServiceDiscovered(service.uuid.description)
                }
            }
            catch {
                Self.log("Connection error: \(error)")
                onError("\(error)")
            }
        }
    }

    func disconnect(address: String) {
        guard let central, let peripheral = peripheral(for: address) else {
            return
        }
        Task {
            await central.disconnect(peripheral)
        }
    }

    private func peripheral(for address: String) -> Peripheral? {
        guard let address = BluetoothAddress(rawValue: address) else {
            return nil
        }
        return Peripheral(id: address)
    }

    private static func log(_ message: String) {
        try? AndroidLogger(tag: "BluetoothDemo", priority: .debug).log(message)
    }
}
