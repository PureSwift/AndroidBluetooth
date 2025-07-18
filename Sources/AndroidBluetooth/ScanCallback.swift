// Auto-generated by Java-to-Swift wrapper generator.
import JavaKit
import JavaKitCollection
import JavaRuntime

@JavaClass("android.bluetooth.le.ScanCallback")
open class ScanCallback: JavaObject {
  @JavaMethod
  @_nonoverride public convenience init(environment: JNIEnvironment? = nil)

  @JavaMethod
  open func onScanResult(_ arg0: Int32, _ arg1: ScanResult?)

  @JavaMethod
  open func onBatchScanResults(_ arg0: List<ScanResult>?)

  @JavaMethod
  open func onScanFailed(_ arg0: Int32)
}
extension JavaClass<ScanCallback> {
  @JavaStaticField(isFinal: true)
  public var SCAN_FAILED_ALREADY_STARTED: Int32

  @JavaStaticField(isFinal: true)
  public var SCAN_FAILED_APPLICATION_REGISTRATION_FAILED: Int32

  @JavaStaticField(isFinal: true)
  public var SCAN_FAILED_FEATURE_UNSUPPORTED: Int32

  @JavaStaticField(isFinal: true)
  public var SCAN_FAILED_INTERNAL_ERROR: Int32

  @JavaStaticField(isFinal: true)
  public var SCAN_FAILED_OUT_OF_HARDWARE_RESOURCES: Int32

  @JavaStaticField(isFinal: true)
  public var SCAN_FAILED_SCANNING_TOO_FREQUENTLY: Int32
}
