// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaRuntime

@JavaClass("android.bluetooth.le.ScanFilter", implements: Parcelable.self)
open class ScanFilter: JavaObject {
  @JavaMethod
  open func getDeviceAddress() -> String

  @JavaMethod
  open func getServiceDataMask() -> [Int8]

  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func getServiceData() -> [Int8]

  @JavaMethod
  open func getDeviceName() -> String

  @JavaMethod
  open func getServiceUuid() -> ParcelUuid!

  @JavaMethod
  open func getServiceUuidMask() -> ParcelUuid!

  @JavaMethod
  open func getServiceDataUuid() -> ParcelUuid!

  @JavaMethod
  open func getManufacturerId() -> Int32

  @JavaMethod
  open func getAdvertisingData() -> [Int8]

  @JavaMethod
  open func getServiceSolicitationUuid() -> ParcelUuid!

  @JavaMethod
  open func getServiceSolicitationUuidMask() -> ParcelUuid!

  @JavaMethod
  open func getManufacturerData() -> [Int8]

  @JavaMethod
  open func getManufacturerDataMask() -> [Int8]

  @JavaMethod
  open func getAdvertisingDataType() -> Int32

  @JavaMethod
  open func getAdvertisingDataMask() -> [Int8]

  @JavaMethod
  open override func equals(_ arg0: JavaObject?) -> Bool

  @JavaMethod
  open override func toString() -> String

  @JavaMethod
  open override func hashCode() -> Int32

  @JavaMethod
  open func matches(_ arg0: ScanResult?) -> Bool
}
extension JavaClass<ScanFilter> {
  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<ScanFilter>!

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
