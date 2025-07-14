//
//  AndroidAdvertisement.swift
//  BluetoothExplorerAndroid
//
//  Created by Alsey Coleman Miller on 11/7/18.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import Bluetooth
import BluetoothGAP
import GATT

/// Android's BLE Advertisement data
public struct AndroidLowEnergyAdvertisementData: Equatable {
    
    public let data: Data
    
    internal init(data: Data) {
        self.data = data
    }
}

extension AndroidLowEnergyAdvertisementData: AdvertisementData {
    
    #if canImport(FoundationEssentials)
    public typealias Data = FoundationEssentials.Data
    #elseif canImport(Foundation)
    public typealias Data = Foundation.Data
    #endif
    
    /// The local name of a peripheral.
    public var localName: String? {
        
        if let decoded = try? GAPDataDecoder.decode(GAPCompleteLocalName.self, from: data) {
            return decoded.name
        } else if let decoded = try? GAPDataDecoder.decode(GAPShortLocalName.self, from: data) {
            return decoded.name
        } else {
            return nil
        }
    }
    
    /// The Manufacturer data of a peripheral.
    public var manufacturerData: GAPManufacturerSpecificData<Data>? {
        
        guard let value = try? GAPDataDecoder.decode(GAPManufacturerSpecificData<Data>.self, from: data)
            else { return nil }
        
        return ManufacturerSpecificData(
            companyIdentifier: value.companyIdentifier,
            additionalData: value.additionalData
        )
    }
    
    /// Service-specific advertisement data.
    public var serviceData: [BluetoothUUID: Data]? {
        
        var serviceData = [BluetoothUUID: Data](minimumCapacity: 3)
        
        if let value = try? GAPDataDecoder.decode(GAPServiceData16BitUUID<Data>.self, from: data) {
            serviceData[.bit16(value.uuid)] = value.serviceData
        }
        if let value = try? GAPDataDecoder.decode(GAPServiceData32BitUUID<Data>.self, from: data) {
            serviceData[.bit32(value.uuid)] = value.serviceData
        }
        if let value = try? GAPDataDecoder.decode(GAPServiceData128BitUUID<Data>.self, from: data) {
            serviceData[.bit128(UInt128(uuid: value.uuid))] = value.serviceData
        }
        
        guard serviceData.isEmpty == false
            else { return nil }
        
        return serviceData
    }
    
    /// An array of service UUIDs
    public var serviceUUIDs: [BluetoothUUID]? {
        
        var uuids = [BluetoothUUID]()
        uuids.reserveCapacity(2)
        
        if let value = try? GAPDataDecoder.decode(GAPCompleteListOf16BitServiceClassUUIDs.self, from: data) {
            uuids += value.uuids.map { .bit16($0) }
        }
        if let value = try? GAPDataDecoder.decode(GAPIncompleteListOf16BitServiceClassUUIDs.self, from: data) {
            uuids += value.uuids.map { .bit16($0) }
        }
        if let value = try? GAPDataDecoder.decode(GAPIncompleteListOf32BitServiceClassUUIDs.self, from: data) {
            uuids += value.uuids.map { .bit32($0) }
        }
        if let value = try? GAPDataDecoder.decode(GAPIncompleteListOf32BitServiceClassUUIDs.self, from: data) {
            uuids += value.uuids.map { .bit32($0) }
        }
        if let value = try? GAPDataDecoder.decode(GAPCompleteListOf128BitServiceClassUUIDs.self, from: data) {
            uuids += value.uuids.map { .init(uuid: $0) }
        }
        if let value = try? GAPDataDecoder.decode(GAPIncompleteListOf128BitServiceClassUUIDs.self, from: data) {
            uuids += value.uuids.map { .init(uuid: $0) }
        }
        
        guard uuids.isEmpty == false
            else { return nil }
        
        return uuids
    }
    
    /// This value is available if the broadcaster (peripheral) provides its Tx power level in its advertising packet.
    /// Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    public var txPowerLevel: Double? {
        
        guard let value = try? GAPDataDecoder.decode(GAPTxPowerLevel.self, from: data)
            else { return nil }
        
        return Double(value.powerLevel)
    }
    
    /// An array of one or more `BluetoothUUID`, representing Service UUIDs.
    public var solicitedServiceUUIDs: [BluetoothUUID]? {
        
        var uuids = [BluetoothUUID]()
        uuids.reserveCapacity(2)
        
        if let value = try? GAPDataDecoder.decode(GAPListOf16BitServiceSolicitationUUIDs.self, from: data) {
            uuids += value.uuids.map { .bit16($0) }
        }
        if let value = try? GAPDataDecoder.decode(GAPListOf32BitServiceSolicitationUUIDs.self, from: data) {
            uuids += value.uuids.map { .bit32($0) }
        }
        if let value = try? GAPDataDecoder.decode(GAPListOf128BitServiceSolicitationUUIDs.self, from: data) {
            uuids += value.uuids.map { .init(uuid: $0) }
        }
        
        guard uuids.isEmpty == false
            else { return nil }
        
        return uuids
    }
}
