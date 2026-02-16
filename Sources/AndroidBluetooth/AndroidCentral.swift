//
//  AndroidCentral.swift
//  Android
//
//  Created by Marco Estrella on 7/24/18.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import GATT
import Bluetooth
import SwiftJava
import JavaLang
import JavaUtil
import JavaLangUtil
import AndroidOS
import AndroidContent
import AndroidManifest

/// Android GATT Central
public final class AndroidCentral: CentralManager {
    
    public typealias Advertisement = AndroidLowEnergyAdvertisementData
    
    public typealias AttributeID = String
    
    // MARK: - Properties
    
    public nonisolated(unsafe) var log: (@Sendable (String) -> ())?
    
    public let hostController: BluetoothAdapter
    
    public let context: AndroidContent.Context
    
    public var peripherals: [GATT.Peripheral : Bool] {
        get async {
            [:] // FIXME:
        }
    }
    
    public var isEnabled: Bool {
        get async {
            do {
                if #available(Android 31, *) {
                    try checkPermission(.bluetoothScan)
                } else {
                    try checkPermission(.bluetooth)
                }
            }
            catch {
                return false
            }
            // Make sure hardware is on
            return hostController.isEnabled()
                && hostController.getBluetoothLeScanner() != nil
        }
    }
    
    public let options: Options
    
    internal let storage = Storage()
    
    // MARK: - Intialization
    
    public init(
        hostController: BluetoothAdapter,
        context: AndroidContent.Context,
        options: AndroidCentral.Options = Options()) {
        
        self.hostController = hostController
        self.context = context
        self.options = options
    }
    
    // MARK: - Methods
    
    public func scan(
        filterDuplicates: Bool = true
    ) async throws -> AsyncCentralScan<AndroidCentral> {
        
        log?("\(type(of: self)) \(#function)")
        
        if #available(Android 31, *) {
            try checkPermission(.bluetoothScan)
        } else {
            try checkPermission(.bluetooth)
        }
        
        guard hostController.isEnabled()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        guard let scanner = hostController.getBluetoothLeScanner()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        // check permission
        let permission = try Permission(rawValue: JavaClass<Manifest.Permission>().BLUETOOTH_SCAN)
        try checkPermission(permission)
        
        return .init(onTermination: {
            Task {
                await self.stopScan()
            }
        }, { continuation in
            Task {
                await storage.update {
                    $0.scan.peripherals.removeAll()
                    $0.scan.continuation = continuation
                }
                let scanCallBack = LowEnergyScanCallback(central: self)
                do {
                    try scanner.startScan(scanCallBack)
                    await storage.update {
                        $0.scan.callback = scanCallBack
                    }
                }
                catch {
                    continuation.finish(throwing: error)
                    await storage.update {
                        $0.scan.peripherals.removeAll()
                        $0.scan.continuation = nil
                    }
                }
            }
        })
    }
    
    /// Connect to the specified device.
    public func connect(to peripheral: Peripheral) async throws {
        try await connect(to: peripheral, autoConnect: true, transport: .le)
    }
    
    /// Connect to the specified device.
    public func connect(
        to peripheral: Peripheral,
        autoConnect: Bool,
        transport: BluetoothTransport
    ) async throws {
        
        log?("\(type(of: self)) \(#function)")
        
        guard hostController.isEnabled()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        guard let scanDevice = await storage.state.scan.peripherals[peripheral]
            else { throw CentralError.unknownPeripheral }
        
        // wait for connection continuation
        do {
            try await withCheckedThrowingContinuation { continuation in
                Task {
                    // attempt to connect (does not timeout)
                    await storage.update { [unowned self] state in
                        
                        // store continuation
                        let callback = GattCallback() //GattCallback(self)
                        let gatt: BluetoothGatt
                        
                        // call the correct method for connecting
                        let sdkInt = try! JavaClass<AndroidOS.Build.VERSION>().SDK_INT
                        let lollipopMr1 = try! JavaClass<AndroidOS.Build.VERSION_CODES>().LOLLIPOP_MR1
                        if sdkInt <= lollipopMr1 {
                            gatt = try! scanDevice.scanResult.getDevice().connectGatt(
                                context: self.context,
                                autoConnect: autoConnect,
                                callback: callback
                            )
                        } else {
                            gatt = try! scanDevice.scanResult.getDevice().connectGatt(
                                context: self.context,
                                autoConnect: autoConnect,
                                callback: callback,
                                transport: transport
                            )
                        }
                        var cache = Cache(gatt: gatt, callback: callback)
                        cache.continuation.connect = continuation
                        state.cache[peripheral] = cache
                    }
                }
            }
        }
        catch let error as CancellationError {
            // cancel connection if we timeout or cancel
            await storage.update { state in
                
                // Close, disconnect or cancel connection
                state.cache[peripheral]?.gatt.disconnect()
                state.cache[peripheral]?.gatt.close()
                state.cache[peripheral] = nil
            }
            throw error
        }
        
        // negotiate MTU
        let currentMTU = try await self.maximumTransmissionUnit(for: peripheral)
        if options.maximumTransmissionUnit != currentMTU {
            log?("Current MTU is \(currentMTU), requesting \(options.maximumTransmissionUnit)")
            let mtuResponse = try await self.request(mtu: options.maximumTransmissionUnit, for: peripheral)
            let newMTU = try await self.maximumTransmissionUnit(for: peripheral)
            assert(mtuResponse == newMTU)
        }
    }
    
    /// Disconnect the specified device.
    public func disconnect(_ peripheral: Peripheral) async {
        
        log?("\(type(of: self)) \(#function)")
        
        await storage.update { state in
            state.cache[peripheral]?.gatt.disconnect()
            state.cache[peripheral]?.gatt.close()
            state.cache[peripheral] = nil
        }
    }
    
    /// Disconnect all connected devices.
    public func disconnectAll() async {
        
        log?("\(type(of: self)) \(#function)")
        
        await storage.update { state in
            state.cache.values.forEach {
                $0.gatt.disconnect()
                $0.gatt.close()
            }
            state.cache.removeAll()
        }
    }
    
    /// Discover Services
    public func discoverServices(
        _ services: Set<BluetoothUUID>,
        for peripheral: Peripheral
    ) async throws -> [Service<Peripheral, AttributeID>] {
        
        log?("\(type(of: self)) \(#function)")
        
        guard hostController.isEnabled()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await storage.update { state in
                        // store continuation
                        state.cache[peripheral]?.continuation.discoverServices = continuation
                        
                        guard state.scan.peripherals.keys.contains(peripheral)
                            else { throw CentralError.unknownPeripheral }
                        
                        guard let cache = state.cache[peripheral]
                            else { throw CentralError.disconnected }
                        
                        guard cache.gatt.discoverServices()
                            else { throw AndroidCentralError.binderFailure }
                    }
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Discover Characteristics for service
    public func discoverCharacteristics(
        _ characteristics: Set<BluetoothUUID>,
        for service: Service<Peripheral, AttributeID>
    ) async throws -> [Characteristic<Peripheral, AttributeID>] {
        
        log?("\(type(of: self)) \(#function)")
        
        return try await storage.update { state in
            
            guard let cache = state.cache[service.peripheral]
                else { throw CentralError.disconnected }
            
            guard let gattService = cache.services.values[service.id]
                else { throw CentralError.invalidAttribute(service.uuid) }
            
            let gattCharacteristics = gattService
                .getCharacteristics()
                .toArray()
                .map { $0!.as(BluetoothGattCharacteristic.self)! }
            
            guard let services = state.cache[service.peripheral]?.update(gattCharacteristics, for: service) else {
                assertionFailure("Missing connection cache")
                return []
            }
            
            return services
        }
    }
    
    /// Read Characteristic Value
    public func readValue(
        for characteristic: Characteristic<Peripheral, AttributeID>
    ) async throws -> Data {
        
        log?("\(type(of: self)) \(#function)")
        
        guard hostController.isEnabled()
        else { throw AndroidCentralError.bluetoothDisabled }
        
        let peripheral = characteristic.peripheral
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await storage.update { state in
                        // store continuation
                        state.cache[peripheral]?.continuation.readCharacteristic = continuation
                        
                        guard state.scan.peripherals.keys.contains(peripheral)
                            else { throw CentralError.unknownPeripheral }
                        
                        guard let cache = state.cache[peripheral]
                            else { throw CentralError.disconnected }
                        
                        guard let gattCharacteristic = cache.characteristics.values[characteristic.id]?.object
                            else { throw CentralError.invalidAttribute(characteristic.uuid) }
                        
                        guard cache.gatt.readCharacteristic(gattCharacteristic)
                            else { throw AndroidCentralError.binderFailure }
                    }
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Write Characteristic Value
    public func writeValue(
        _ data: Data,
        for characteristic: Characteristic<Peripheral, AttributeID>,
        withResponse: Bool
    ) async throws {
        
        log?("\(type(of: self)) \(#function)")
        
        guard hostController.isEnabled()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        let peripheral = characteristic.peripheral
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await storage.update { state in
                        // store continuation
                        state.cache[peripheral]?.continuation.writeCharacteristic = continuation
                        
                        guard state.scan.peripherals.keys.contains(peripheral)
                            else { throw CentralError.unknownPeripheral }
                        
                        guard let cache = state.cache[peripheral]
                            else { throw CentralError.disconnected }
                        
                        guard let gattCharacteristic = cache.characteristics.values[characteristic.id]?.object
                            else { throw CentralError.invalidAttribute(characteristic.uuid) }
                        
                        let dataArray = [UInt8](data)
                        let _ = gattCharacteristic.setValue(unsafeBitCast(dataArray, to: [Int8].self))
                        
                        guard cache.gatt.writeCharacteristic(gattCharacteristic)
                            else { throw AndroidCentralError.binderFailure }
                    }
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Discover descriptors
    public func discoverDescriptors(
        for characteristic: Characteristic<Peripheral, AttributeID>
    ) async throws -> [Descriptor<Peripheral, AttributeID>] {
        
        log?("\(type(of: self)) \(#function)")
        
        guard hostController.isEnabled()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        let peripheral = characteristic.peripheral
        
        return try await storage.update { state in
            
            guard let cache = state.cache[peripheral]
                else { throw CentralError.disconnected }
            
            guard let gattCharacteristic = cache.characteristics.values[characteristic.id]?.object
                else { throw CentralError.invalidAttribute(characteristic.uuid) }
            
            let gattDescriptors = gattCharacteristic
                .getDescriptors()
                .toArray()
                .map { BluetoothGattDescriptor(javaHolder: $0!.javaHolder) }
            
            return state.cache[peripheral]?.update(gattDescriptors, for: characteristic) ?? []
        }
    }
    
    /// Read descriptor
    public func readValue(
        for descriptor: Descriptor<Peripheral, AttributeID>
    ) async throws -> Data {
        
        log?("\(type(of: self)) \(#function)")
        
        guard hostController.isEnabled()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        let peripheral = descriptor.peripheral
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await storage.update { state in
                        // store continuation
                        state.cache[peripheral]?.continuation.readDescriptor = continuation
                        
                        guard state.scan.peripherals.keys.contains(peripheral)
                            else { throw CentralError.unknownPeripheral }
                        
                        guard let gatt = state.cache[peripheral]?.gatt
                            else { throw CentralError.disconnected }
                                                
                        guard let gattDescriptor = state.cache[peripheral]?.descriptors.values[descriptor.id]
                            else { throw CentralError.invalidAttribute(descriptor.uuid) }
                        
                        guard gatt.readDescriptor(gattDescriptor)
                            else { throw AndroidCentralError.binderFailure }
                    }
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Write descriptor
    public func writeValue(
        _ data: Data,
        for descriptor: Descriptor<Peripheral, AttributeID>
    ) async throws {
        
        log?("\(type(of: self)) \(#function)")
        
        guard hostController.isEnabled()
        else { throw AndroidCentralError.bluetoothDisabled }
        
        let peripheral = descriptor.peripheral
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await storage.update { state in
                        // store continuation
                        state.cache[peripheral]?.continuation.writeDescriptor = continuation
                        
                        guard state.scan.peripherals.keys.contains(peripheral)
                            else { throw CentralError.unknownPeripheral }
                        
                        guard let cache = state.cache[peripheral]
                            else { throw CentralError.disconnected }
                        
                        guard let gattDescriptor = cache.descriptors.values[descriptor.id]
                            else { throw CentralError.invalidAttribute(descriptor.uuid) }
                        
                        let dataArray = [UInt8](data)
                        let _ = gattDescriptor.setValue(unsafeBitCast(dataArray, to: [Int8].self))
                        
                        guard cache.gatt.writeDescriptor(gattDescriptor)
                            else { throw AndroidCentralError.binderFailure }
                    }
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Start Notifications
    public func notify(
        for characteristic: Characteristic<Peripheral, AttributeID>
    ) async throws -> AsyncCentralNotifications<AndroidCentral> {
        fatalError()
    }
    
    /// Read MTU
    public func maximumTransmissionUnit(for peripheral: Peripheral) async throws -> MaximumTransmissionUnit {
        
        guard hostController.isEnabled()
        else { throw AndroidCentralError.bluetoothDisabled }
        
        guard let cache = await storage.state.cache[peripheral]
        else { throw CentralError.disconnected }
        
        return cache.maximumTransmissionUnit // cached MTU
    }
    
    // Read RSSI
    public func rssi(for peripheral: Peripheral) async throws -> RSSI {
        
        guard hostController.isEnabled()
        else { throw AndroidCentralError.bluetoothDisabled }
        
        let rawValue = try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await storage.update { state in
                        // store continuation
                        state.cache[peripheral]?.continuation.readRemoteRSSI = continuation
                        
                        guard state.scan.peripherals.keys.contains(peripheral)
                        else { throw CentralError.unknownPeripheral }
                        
                        guard let cache = state.cache[peripheral]
                        else { throw CentralError.disconnected }
                        
                        guard cache.gatt.readRemoteRssi()
                        else { throw AndroidCentralError.binderFailure }
                    }
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        guard let value = RSSI(rawValue: numericCast(rawValue)) else {
            assertionFailure()
            return RSSI(rawValue: -127)!
        }
        
        return value
    }
    
    // MARK: - Private Methods
    
    private func checkPermission(_ permission: AndroidManifest.Permission) throws {
        let permissionGranted = try JavaClass<AndroidContent.PackageManager>().PERMISSION_GRANTED
        let status = context.checkSelfPermission(permission.rawValue)
        guard status == permissionGranted else {
            throw AndroidCentralError.bluetoothDisabled
        }
    }
    
    private func stopScan() async {
        
        guard hostController.isEnabled()
            else { return }
        
        guard let scanner = hostController.getBluetoothLeScanner()
            else { return }
        
        guard let scanCallBack = await self.storage.state.scan.callback
            else { return }
        
        scanner.stopScan(scanCallBack)
    }
    
    @discardableResult
    private func request(mtu: MaximumTransmissionUnit, for peripheral: Peripheral) async throws -> MaximumTransmissionUnit {
        
        guard let _ = await storage.state.scan.peripherals[peripheral]
            else { throw CentralError.unknownPeripheral }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // need to connect first
                    guard let cache = await storage.state.cache[peripheral]
                        else { throw CentralError.disconnected }
                    
                    await storage.update { state in
                        state.cache[peripheral]?.continuation.exchangeMTU = continuation
                    }
                    
                    guard cache.gatt.requestMtu(Int32(mtu.rawValue))
                        else { throw AndroidCentralError.binderFailure }
                }
                catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /*
    public func notify(_ notification: ((Data) -> ())?, for characteristic: Characteristic<Peripheral>) throws {
        
        log?("\(type(of: self)) \(#function) started")
        
        guard hostController.isEnabled()
        else { throw AndroidCentralError.bluetoothDisabled }
        
        let enable = notification != nil
        
        // store semaphore
        let semaphore = Semaphore(timeout: timeout)
        await storage.update { [unowned self] in self.internalState.notify.semaphore = semaphore }
        defer { await storage.update { [unowned self] in self.internalState.notify.semaphore = nil } }
        
        try await storage.update { [unowned self] in
            
            guard let cache = self.internalState.cache[characteristic.peripheral]
            else { throw CentralError.disconnected }
            
            guard let gattCharacteristic = cache.characteristics.values[characteristic.identifier]?.attribute
            else { throw AndroidCentralError.characteristicNotFound }
            
            guard cache.gatt.setCharacteristicNotification(characteristic: gattCharacteristic, enable: enable) else {
                throw AndroidCentralError.binderFailure
            }
            
            let uuid = java_util.UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")!
            
            guard let descriptor = gattCharacteristic.getDescriptor(uuid: uuid) else {
                log?("\(BluetoothUUID.clientCharacteristicConfiguration) descriptor does not exist")
                throw AndroidCentralError.binderFailure
            }
            
            let valueEnableNotification : [Int8] = enable ? AndroidBluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE : AndroidBluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            
            let wasLocallyStored = descriptor.setValue(valueEnableNotification)
            
            guard cache.gatt.writeDescriptor(descriptor: descriptor) else {
                throw AndroidCentralError.binderFailure
            }
            
            self.log?("\(type(of: self)) \(#function) \(enable ? "start": "stop") : true , locallyStored: \(wasLocallyStored)")
        }
        
        // throw async error
        do { try semaphore.wait() }
        
        try await storage.update { [unowned self] in
            
            guard let cache = self.internalState.cache[characteristic.peripheral]
            else { throw CentralError.disconnected }
            
            cache.update(identifier: characteristic.identifier, notification: notification)
        }
        
        NSLog("\(type(of: self)) \(#function) finished")
    }*/
}

// MARK: - Supporting Types

public extension AndroidCentral {
    
    /// Android GATT Central options
    struct Options {
        
        public let maximumTransmissionUnit: MaximumTransmissionUnit
        
        public init(maximumTransmissionUnit: MaximumTransmissionUnit = .max) {
            self.maximumTransmissionUnit = maximumTransmissionUnit
        }
    }
}

