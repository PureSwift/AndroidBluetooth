//
//  ScanData.swift
//  AndroidBluetooth
//
//  Created by Alsey Coleman Miller on 7/13/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import SwiftJava
import AndroidOS
import Bluetooth
import GATT

internal extension ScanData where Peripheral == AndroidCentral.Peripheral, Advertisement == AndroidCentral.Advertisement {
    
    init(_ result: ScanResult) throws {
        
        let peripheral = Peripheral(result.getDevice())
        let record = result.getScanRecord()!
        let advertisement = AndroidLowEnergyAdvertisementData(data: Data(record.bytes))
        let isConnectable: Bool
        let sdkInt = try JavaClass<AndroidOS.Build.VERSION>().SDK_INT
        let oVersion = try JavaClass<AndroidOS.Build.VERSION_CODES>().O
        if sdkInt >= oVersion {
            isConnectable = result.isConnectable()
        } else {
            isConnectable = true
        }
        self.init(
            peripheral: peripheral,
            date: Date(),
            rssi: Double(result.getRssi()),
            advertisementData: advertisement,
            isConnectable: isConnectable
        )
    }
}
