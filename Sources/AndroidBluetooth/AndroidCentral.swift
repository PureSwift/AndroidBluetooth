//
//  AndroidCentral.swift
//  Android
//
//  Created by Marco Estrella on 7/24/18.
//

import Foundation
import GATT
import Bluetooth
import Android
import java_swift
import java_util

public final class AndroidCentral: CentralManager {
    
    public typealias Advertisement = AndroidLowEnergyAdvertisementData
    
    public typealias AttributeID = String
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    public let hostController: Android.Bluetooth.Adapter
    
    public let context: Android.Content.Context
    
    public var peripherals: [GATT.Peripheral : Bool] {
        get async {
            [:] // FIXME:
        }
    }
        
    public let options: Options
    
    private let storage = Storage()
    
    // MARK: - Intialization
    
    public init(hostController: Android.Bluetooth.Adapter,
                context: Android.Content.Context,
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
        
        guard hostController.isEnabled()
            else { throw AndroidCentralError.bluetoothDisabled }
        
        guard let scanner = hostController.lowEnergyScanner
            else { throw AndroidCentralError.nullValue(\Android.Bluetooth.Adapter.lowEnergyScanner) }
        
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
                let scanCallBack = ScanCallback()
                scanCallBack.central = self
                scanner.startScan(callback: scanCallBack)
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
        transport: Android.Bluetooth.Device.Transport
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
                        let callback = GattCallback(central: self)
                        let gatt: AndroidBluetoothGatt
                        
                        // call the correct method for connecting
                        if Android.OS.Build.Version.Sdk.sdkInt.rawValue <= Android.OS.Build.VersionCodes.lollipopMr1 {
                            gatt = scanDevice.scanResult.device.connectGatt(
                                context: self.context,
                                autoConnect: autoConnect,
                                callback: callback
                            )
                        } else {
                            gatt = scanDevice.scanResult.device.connectGatt(
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
                else { throw AndroidCentralError.binderFailure }
            
            let gattCharacteristics = gattService.getCharacteristics()
            
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
                        
                        guard let gattCharacteristic = cache.characteristics.values[characteristic.id]?.attribute
                            else { throw AndroidCentralError.characteristicNotFound }
                        
                        guard cache.gatt.readCharacteristic(characteristic: gattCharacteristic)
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
                        
                        guard let gattCharacteristic = cache.characteristics.values[characteristic.id]?.attribute
                            else { throw AndroidCentralError.characteristicNotFound }
                        
                        let dataArray = [UInt8](data)
                        let _ = gattCharacteristic.setValue(value: unsafeBitCast(dataArray, to: [Int8].self))
                        
                        guard cache.gatt.writeCharacteristic(characteristic: gattCharacteristic)
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
        
        return try await storage.update { state in
            
            guard let cache = state.cache[characteristic.peripheral]
                else { throw CentralError.disconnected }
            
            guard let gattCharacteristic = cache.characteristics.values[characteristic.id]?.attribute
                else { throw AndroidCentralError.characteristicNotFound }
                        
            guard let services = state.cache[characteristic.peripheral]?.update(gattCharacteristics, for: service) else {
                assertionFailure("Missing connection cache")
                return []
            }
            
            return services
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
                        
                        let characteristicID = descriptor
                        
                        guard let gattDescriptor = cache.characteristics.values[descriptor.id]?.attribute
                            else { throw AndroidCentralError.characteristicNotFound }
                        
                        guard gatt.readDescriptor(descriptor: gattDescriptor)
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
                        
                        guard let gattDescriptor = cache.characteristics.values[descriptor.id]?.attribute
                            else { throw AndroidCentralError.characteristicNotFound }
                        
                        let dataArray = [UInt8](data)
                        let _ = gattDescriptor.setValue(value: unsafeBitCast(dataArray, to: [Int8].self))
                        
                        guard cache.gatt.writeDescriptor(descriptor: gattDescriptor)
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
    
    private func stopScan() async {
        
        guard hostController.isEnabled()
            else { return }
        
        guard let scanner = hostController.lowEnergyScanner
            else { return }
        
        guard let scanCallBack = await self.storage.state.scan.callback
            else { return }
        
        scanner.stopScan(callback: scanCallBack)
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
                    
                    guard cache.gatt.requestMtu(mtu: Int(mtu.rawValue))
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
    }
    */
    
    // MARK: Android
    
    fileprivate class ScanCallback: Android.Bluetooth.LE.ScanCallback {
        
        weak var central: AndroidCentral?
        
        public required init(javaObject: jobject?) {
            super.init(javaObject: javaObject)
        }
        
        convenience init() {
            self.init(javaObject: nil)
            bindNewJavaObject()
        }
        
        public override func onScanResult(
            callbackType: Android.Bluetooth.LE.ScanCallbackType,
            result: Android.Bluetooth.LE.ScanResult
        ) {
            
            central?.log?("\(type(of: self)) \(#function) name: \(result.device.getName() ?? "") address: \(result.device.address)")
            
            let scanData = ScanData(result)
            
            Task {
                await central?.storage.update { state in
                    state.scan.continuation?.yield(scanData)
                    state.scan.peripherals[scanData.peripheral] = InternalState.Scan.Device(
                        scanData: scanData,
                        scanResult: result
                    )
                }
            }
        }
        
        public override func onBatchScanResults(results: [Android.Bluetooth.LE.ScanResult]) {
            
            central?.log?("\(type(of: self)): \(#function)")
            
            for result in results {
                
                let scanData = ScanData(result)
                
                Task {
                    await central?.storage.update { state in
                        state.scan.continuation?.yield(scanData)
                        state.scan.peripherals[scanData.peripheral] = InternalState.Scan.Device(
                            scanData: scanData,
                            scanResult: result
                        )
                    }
                }
            }
        }
        
        public override func onScanFailed(error: AndroidBluetoothLowEnergyScanCallback.Error) {
            
            central?.log?("\(type(of: self)): \(#function)")
            
            Task {
                await central?.storage.update { state in
                    state.scan.continuation?.finish(throwing: error)
                }
            }
        }
    }
    
    public class GattCallback: Android.Bluetooth.GattCallback {
        
        private weak var central: AndroidCentral?
        
        convenience init(central: AndroidCentral) {
            self.init(javaObject: nil)
            bindNewJavaObject()
            
            self.central = central
        }
        
        public required init(javaObject: jobject?) {
            super.init(javaObject: javaObject)
        }
        
        public override func onConnectionStateChange(
            gatt: Android.Bluetooth.Gatt,
            status: Android.Bluetooth.Gatt.Status,
            newState: Android.Bluetooth.Device.State
        ) {
            let log = central?.log
            log?("\(type(of: self)): \(#function)")
            log?("Status: \(status) - newState: \(newState)")
            
            let peripheral = Peripheral(gatt)
            
            Task {
                await central?.storage.update { state in
                    switch (status, newState) {
                    case (.success, .connected):
                        log?("\(peripheral) Connected")
                        // if we are expecting a new connection
                        if state.cache[peripheral]?.continuation.connect != nil {
                            state.cache[peripheral]?.continuation.connect?.resume()
                            state.cache[peripheral]?.continuation.connect = nil
                        }
                    case (.success, .disconnected):
                        log?("\(peripheral) Disconnected")
                        state.cache[peripheral] = nil
                    default:
                        log?("\(peripheral) Status Error")
                        state.cache[peripheral]?.continuation.connect?.resume(throwing: status) // throw `status` error
                        state.cache[peripheral]?.continuation.connect = nil
                    }
                }
            }
        }
        
        public override func onServicesDiscovered(
            gatt: Android.Bluetooth.Gatt,
            status: Android.Bluetooth.Gatt.Status
        ) {
            let log = central?.log
            let peripheral = Peripheral(gatt)
            log?("\(type(of: self)): \(#function) Status: \(status)")
            
            Task {
                await central?.storage.update { state in
                    // success discovering
                    switch status {
                    case .success:
                        guard let services = state.cache[peripheral]?.update(gatt.services) else {
                            assertionFailure()
                            return
                        }
                        state.cache[peripheral]?.continuation.discoverServices?.resume(returning: services)
                    default:
                        state.cache[peripheral]?.continuation.discoverServices?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.discoverServices = nil
                }
            }
        }
        
        public override func onCharacteristicChanged(
            gatt: Android.Bluetooth.Gatt,
            characteristic: Android.Bluetooth.GattCharacteristic
        ) {
            let log = central?.log
            log?("\(type(of: self)): \(#function)")
            
            let peripheral = Peripheral(gatt)
                        
            Task {
                await central?.storage.update { state in
                    
                    guard let uuid = characteristic.getUUID().toString() else {
                        assertionFailure()
                        return
                    }
                    
                    guard let cache = state.cache[peripheral] else {
                        assertionFailure("Invalid cache for \(uuid)")
                        return
                    }
                    
                    log?("Characteristic \(uuid) count: \(cache.characteristics.values.count)")
                    
                    let id = cache.identifier(for: characteristic)
                    
                    let data = characteristic.getValue()
                        .map { Data(unsafeBitCast($0, to: [UInt8].self)) } ?? Data()
                    
                    guard let characteristicCache = cache.characteristics.values[id] else {
                        assertionFailure("Invalid identifier for \(uuid)")
                        return
                    }
                    
                    guard let notification = characteristicCache.notification else {
                        assertionFailure("Unexpected notification for \(uuid)")
                        return
                    }
                                        
                    notification(data)
                }
            }
        }
        
        public override func onCharacteristicRead(
            gatt: Android.Bluetooth.Gatt,
            characteristic: Android.Bluetooth.GattCharacteristic,
            status: Android.Bluetooth.Gatt.Status
        ) {
            let log = central?.log
            let peripheral = Peripheral(gatt)
            log?("\(type(of: self)): \(#function) \(peripheral) Status: \(status)")
            
            Task {
                await central?.storage.update { state in
                                        
                    switch status {
                    case .success:
                        let data = characteristic.getValue()
                            .map { Data(unsafeBitCast($0, to: [UInt8].self)) } ?? Data()
                        state.cache[peripheral]?.continuation.readCharacteristic?.resume(returning: data)
                    default:
                        state.cache[peripheral]?.continuation.readCharacteristic?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.readCharacteristic = nil
                }
            }
        }
        
        public override func onCharacteristicWrite(
            gatt: Android.Bluetooth.Gatt,
            characteristic: Android.Bluetooth.GattCharacteristic,
            status: Android.Bluetooth.Gatt.Status
        ) {
            
            central?.log?("\(type(of: self)): \(#function)")
            
            let peripheral = Peripheral(gatt)
            
            Task {
                await central?.storage.update { state in
                    switch status {
                    case .success:
                        state.cache[peripheral]?.continuation.writeCharacteristic?.resume()
                    default:
                        state.cache[peripheral]?.continuation.writeCharacteristic?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.writeCharacteristic = nil
                }
            }
        }
        
        public override func onDescriptorRead(
            gatt: Android.Bluetooth.Gatt,
            descriptor: Android.Bluetooth.GattDescriptor,
            status: Android.Bluetooth.Gatt.Status
        ) {
            let peripheral = Peripheral(gatt)
            
            guard let uuid = descriptor.getUUID().toString() else {
                assertionFailure()
                return
            }
            
            central?.log?(" \(type(of: self)): \(#function) \(uuid)")
            
            Task {
                await central?.storage.update { state in
                                        
                    switch status {
                    case .success:
                        let data = descriptor.getValue()
                            .map { Data(unsafeBitCast($0, to: [UInt8].self)) } ?? Data()
                        state.cache[peripheral]?.continuation.readDescriptor?.resume(returning: data)
                    default:
                        state.cache[peripheral]?.continuation.readDescriptor?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.readDescriptor = nil
                }
            }
        }
        
        public override func onDescriptorWrite(
            gatt: Android.Bluetooth.Gatt,
            descriptor: Android.Bluetooth.GattDescriptor,
            status: AndroidBluetoothGatt.Status
        ) {
            
            let peripheral = Peripheral(gatt)
            
            guard let uuid = descriptor.getUUID().toString() else {
                assertionFailure()
                return
            }
            
            central?.log?(" \(type(of: self)): \(#function) \(uuid)")
            
            Task {
                await central?.storage.update { state in
                    switch status {
                    case .success:
                        state.cache[peripheral]?.continuation.writeDescriptor?.resume()
                    default:
                        state.cache[peripheral]?.continuation.writeDescriptor?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.writeDescriptor = nil
                }
            }
        }
        
        public override func onMtuChanged(
            gatt: Android.Bluetooth.Gatt,
            mtu: Int,
            status: Android.Bluetooth.Gatt.Status
        ) {
            central?.log?("\(type(of: self)): \(#function) Peripheral \(Peripheral(gatt)) MTU \(mtu) Status \(status)")
            
            let peripheral = Peripheral(gatt)
            
            guard let central = self.central else {
                assertionFailure()
                return
            }
            
            let oldMTU = central.options.maximumTransmissionUnit
            
            Task {
                
                await central.storage.update { state in
                    
                    // get new MTU value
                    guard let newMTU = MaximumTransmissionUnit(rawValue: UInt16(mtu)) else {
                        assertionFailure("Invalid MTU \(mtu)")
                        return
                    }
                    
                    assert(newMTU <= oldMTU, "Invalid MTU: \(newMTU) > \(oldMTU)")
                    
                    // cache new MTU value
                    state.cache[peripheral]?.maximumTransmissionUnit = newMTU
                    
                    // pending MTU exchange
                    state.cache[peripheral]?.continuation.exchangeMTU?.resume(returning: newMTU)
                    state.cache[peripheral]?.continuation.exchangeMTU = nil
                    return
                }
            }
        }
        
        public override func onPhyRead(gatt: Android.Bluetooth.Gatt, txPhy: Android.Bluetooth.Gatt.TxPhy, rxPhy: Android.Bluetooth.Gatt.RxPhy, status: AndroidBluetoothGatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function)")
        }
        
        public override func onPhyUpdate(gatt: Android.Bluetooth.Gatt, txPhy: Android.Bluetooth.Gatt.TxPhy, rxPhy: Android.Bluetooth.Gatt.RxPhy, status: AndroidBluetoothGatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function)")
        }
        
        public override func onReadRemoteRssi(gatt: Android.Bluetooth.Gatt, rssi: Int, status: Android.Bluetooth.Gatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function) \(rssi) \(status)")
            
            let peripheral = Peripheral(gatt)
            
            Task {
                await central?.storage.update { state in
                    switch status {
                    case .success:
                        state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(returning: rssi)
                    default:
                        state.cache[peripheral]?.continuation.readRemoteRSSI?.resume(throwing: status)
                    }
                    state.cache[peripheral]?.continuation.readRemoteRSSI = nil
                }
            }
        }
        
        public override func onReliableWriteCompleted(gatt: Android.Bluetooth.Gatt, status: AndroidBluetoothGatt.Status) {
            
            central?.log?("\(type(of: self)): \(#function)")
        }
    }
}

// MARK: - Supporting Types

/// Android Central Error
public enum AndroidCentralError: Swift.Error {
    
    /// Bluetooth is disabled.
    case bluetoothDisabled
    
    /// Binder IPC failure.
    case binderFailure
    
    /// Characteristic not found
    case characteristicNotFound
    
    /// Unexpected null value.
    case nullValue(AnyKeyPath)
}

public extension AndroidCentral {
    
    /// Android GATT Central options
    struct Options {
        
        public let maximumTransmissionUnit: MaximumTransmissionUnit
        
        public init(maximumTransmissionUnit: MaximumTransmissionUnit = .max) {
            self.maximumTransmissionUnit = maximumTransmissionUnit
        }
    }
}

// MARK: - Private Supporting Types

internal extension AndroidCentral {
    
    actor Storage {
        
        var state = InternalState()
        
        func update<T>(_ block: (inout InternalState) throws -> (T)) rethrows -> T {
            return try block(&state)
        }
    }
    
    struct InternalState {
        
        fileprivate init() { }
        
        var cache = [Peripheral: Cache]()
        
        var scan = Scan()
        
        struct Scan {
            
            var peripherals = [Peripheral: Device]()
            
            var continuation: AsyncIndefiniteStream<ScanData<Peripheral, AndroidCentral.Advertisement>>.Continuation?
            
            fileprivate var callback: ScanCallback?
            
            struct Device {
                
                let scanData: ScanData<Peripheral, AndroidLowEnergyAdvertisementData>
                
                let scanResult: Android.Bluetooth.LE.ScanResult
            }
        }
    }
    
    /// GATT cache for a connection or peripheral.
    struct Cache {
        
        fileprivate init(
            gatt: Android.Bluetooth.Gatt,
            callback: GattCallback
        ) {
            self.gatt = gatt
            self.gattCallback = callback
        }
        
        let gattCallback: GattCallback
        
        let gatt: Android.Bluetooth.Gatt
        
        fileprivate(set) var maximumTransmissionUnit: MaximumTransmissionUnit = .default
        
        var services = Services()
        
        var characteristics = Characteristics()
                
        var continuation = PeripheralContinuation()
        
        struct Characteristics {
           
            fileprivate(set) var values: [AndroidCentral.AttributeID: CharacteristicCache] = [:]
        }
        
        struct Services {
            
            fileprivate(set) var values: [AndroidCentral.AttributeID: Android.Bluetooth.GattService] = [:]
        }
        
        struct CharacteristicCache {
            
            let object: Android.Bluetooth.GattCharacteristic
            
            var descriptors: [Android.Bluetooth.GattDescriptor] = []
            
            var notification: AsyncIndefiniteStream<Data>.Continuation?
        }
        
        fileprivate func identifier<T>(for attribute: T) -> AndroidCentral.AttributeID where T: AndroidCentralAttribute {
            let peripheral = Peripheral(gatt)
            let instanceID = attribute.getInstanceId()
            guard let uuid = attribute.getUUID().toString() else {
                assertionFailure()
                return instanceID.description
            }
            return "\(peripheral.id)/\(instanceID)/\(uuid)"
        }
        
        fileprivate func identifier(
            for descriptor: Android.Bluetooth.GattDescriptor,
            characteristic: Characteristic<Peripheral, AttributeID>
        ) -> AndroidCentral.AttributeID {
            guard let uuid = descriptor.getUUID().toString() else {
                fatalError()
            }
            return characteristic.id + "/Descriptor/\(uuid)"
        }
        
        fileprivate mutating func update(_ newValues: [Android.Bluetooth.GattService]) -> [Service<Peripheral, AttributeID>] {
            services.values.removeAll(keepingCapacity: true)
            characteristics.values.removeAll(keepingCapacity: true)
            return newValues.map {
                let id = identifier(for: $0)
                let peripheral = Peripheral(gatt)
                let uuid = BluetoothUUID(android: $0.getUUID())
                let isPrimary = $0.getType() == AndroidBluetoothGattService.ServiceType.primary
                // cache value
                services.values[id] = $0
                // map value
                return Service(
                    id: id,
                    uuid: uuid,
                    peripheral: peripheral,
                    isPrimary: isPrimary
                )
            }
        }
        
        fileprivate mutating func update(
            _ newValues: [Android.Bluetooth.GattCharacteristic],
            for service: Service<Peripheral, AttributeID>
        ) -> [Characteristic<Peripheral, AttributeID>] {
            return newValues.map {
                let id = identifier(for: $0)
                let peripheral = Peripheral(gatt)
                let uuid = BluetoothUUID(android: $0.getUUID())
                let properties = BitMaskOptionSet<CharacteristicProperty>(rawValue: UInt8($0.getProperties()))
                // cache
                characteristics.values[id] = CharacteristicCache(object: $0)
                // return Swift value
                return Characteristic(
                    id: id,
                    uuid: uuid,
                    peripheral: peripheral,
                    properties: properties
                )
            }
        }
        
        fileprivate mutating func update(
            _ newValues: [Android.Bluetooth.GattDescriptor],
            for characteristic: Characteristic<Peripheral, AttributeID>
        ) -> [Descriptor<Peripheral, AttributeID>] {
            // cache
            characteristics.values[characteristic.id]?.descriptors = newValues
            // return swift value
            return newValues.map {
                let id = identifier(for: $0, characteristic: characteristic)
                let peripheral = Peripheral(gatt)
                let uuid = BluetoothUUID(android: $0.getUUID())
                return Descriptor(
                    id: id,
                    uuid: uuid,
                    peripheral: peripheral
                )
            }
        }
    }
    
    struct PeripheralContinuation {
        
        var connect: CheckedContinuation<Void, Error>?
        
        var exchangeMTU: CheckedContinuation<MaximumTransmissionUnit, Error>?
        
        var discoverServices: CheckedContinuation<[Service<Peripheral, AttributeID>], Error>?
        
        var discoverCharacteristics: CheckedContinuation<[Characteristic<Peripheral, AttributeID>], Error>?
        
        var discoverDescriptors: CheckedContinuation<[Descriptor<Peripheral, AttributeID>], Error>?
        
        var readCharacteristic: CheckedContinuation<Data, Error>?
        
        var writeCharacteristic: CheckedContinuation<Void, Error>?
        
        var readDescriptor: CheckedContinuation<Data, Error>?
        
        var writeDescriptor: CheckedContinuation<Void, Error>?
        
        var readRemoteRSSI: CheckedContinuation<Int, Error>?
    }
}

internal protocol AndroidCentralAttribute {
    
    func getInstanceId() -> Int
    
    func getUUID() -> java_util.UUID
}

extension Android.Bluetooth.GattService: AndroidCentralAttribute { }

extension Android.Bluetooth.GattCharacteristic: AndroidCentralAttribute { }

// MARK: - Extensions

fileprivate extension Peripheral {
    
    init(_ device: AndroidBluetoothDevice) {
        self.init(id: device.address)
    }
    
    init(_ gatt: AndroidBluetoothGatt) {
        self.init(gatt.getDevice())
    }
}

internal extension BluetoothUUID {
    
    init(android javaUUID: java_util.UUID) {
        
        let uuid = UUID(uuidString: javaUUID.toString())!
        if let value = UInt16(bluetooth: uuid) {
            self = .bit16(value)
        } else {
            self = .bit128(UInt128(uuid: uuid))
        }
    }
}

internal extension ScanData where Peripheral == AndroidCentral.Peripheral, Advertisement == AndroidCentral.Advertisement {
    
    init(_ result: Android.Bluetooth.LE.ScanResult) {
        
        let peripheral = Peripheral(id: result.device.address)
        let record = result.scanRecord
        let advertisement = AndroidLowEnergyAdvertisementData(data: Data(record.bytes))
        let isConnectable: Bool
        if AndroidBuild.Version.Sdk.sdkInt.rawValue >= AndroidBuild.VersionCodes.O {
            isConnectable = result.isConnectable
        } else {
            isConnectable = true
        }
        self.init(
            peripheral: peripheral,
            date: Date(),
            rssi: Double(result.rssi),
            advertisementData: advertisement,
            isConnectable: isConnectable
        )
    }
}
