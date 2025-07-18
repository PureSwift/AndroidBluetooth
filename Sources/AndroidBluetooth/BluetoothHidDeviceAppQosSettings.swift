// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaRuntime

@JavaClass("android.bluetooth.BluetoothHidDeviceAppQosSettings", implements: Parcelable.self)
open class BluetoothHidDeviceAppQosSettings: JavaObject {
  @JavaMethod
  @_nonoverride public convenience init(_ arg0: Int32, _ arg1: Int32, _ arg2: Int32, _ arg3: Int32, _ arg4: Int32, _ arg5: Int32, environment: JNIEnvironment? = nil)

  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func getServiceType() -> Int32

  @JavaMethod
  open func getTokenRate() -> Int32

  @JavaMethod
  open func getTokenBucketSize() -> Int32

  @JavaMethod
  open func getPeakBandwidth() -> Int32

  @JavaMethod
  open func getLatency() -> Int32

  @JavaMethod
  open func getDelayVariation() -> Int32
}
extension JavaClass<BluetoothHidDeviceAppQosSettings> {
  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<BluetoothHidDeviceAppQosSettings>!

  @JavaStaticField(isFinal: true)
  public var MAX: Int32

  @JavaStaticField(isFinal: true)
  public var SERVICE_BEST_EFFORT: Int32

  @JavaStaticField(isFinal: true)
  public var SERVICE_GUARANTEED: Int32

  @JavaStaticField(isFinal: true)
  public var SERVICE_NO_TRAFFIC: Int32

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
