// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaRuntime

extension ScanFilter {
  @JavaClass("android.bluetooth.le.ScanFilter$Builder")
  open class Builder: JavaObject {
  @JavaMethod
  @_nonoverride public convenience init(environment: JNIEnvironment? = nil)

  @JavaMethod
  open func setDeviceName(_ arg0: String) -> ScanFilter.Builder!

  @JavaMethod
  open func setDeviceAddress(_ arg0: String) -> ScanFilter.Builder!

  @JavaMethod
  open func setServiceUuid(_ arg0: ParcelUuid?, _ arg1: ParcelUuid?) -> ScanFilter.Builder!

  @JavaMethod
  open func setServiceUuid(_ arg0: ParcelUuid?) -> ScanFilter.Builder!

  @JavaMethod
  open func setServiceData(_ arg0: ParcelUuid?, _ arg1: [Int8], _ arg2: [Int8]) -> ScanFilter.Builder!

  @JavaMethod
  open func setServiceData(_ arg0: ParcelUuid?, _ arg1: [Int8]) -> ScanFilter.Builder!

  @JavaMethod
  open func setServiceSolicitationUuid(_ arg0: ParcelUuid?, _ arg1: ParcelUuid?) -> ScanFilter.Builder!

  @JavaMethod
  open func setServiceSolicitationUuid(_ arg0: ParcelUuid?) -> ScanFilter.Builder!

  @JavaMethod
  open func setManufacturerData(_ arg0: Int32, _ arg1: [Int8]) -> ScanFilter.Builder!

  @JavaMethod
  open func setManufacturerData(_ arg0: Int32, _ arg1: [Int8], _ arg2: [Int8]) -> ScanFilter.Builder!

  @JavaMethod
  open func setAdvertisingDataTypeWithData(_ arg0: Int32, _ arg1: [Int8], _ arg2: [Int8]) -> ScanFilter.Builder!

  @JavaMethod
  open func setAdvertisingDataType(_ arg0: Int32) -> ScanFilter.Builder!

  @JavaMethod
  open func build() -> ScanFilter!
  }
}
