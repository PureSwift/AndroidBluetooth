// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaRuntime

@JavaClass("android.bluetooth.BluetoothHealthAppConfiguration", implements: Parcelable.self)
open class BluetoothHealthAppConfiguration: JavaObject {
  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func getDataType() -> Int32

  @JavaMethod
  open func getRole() -> Int32

  @JavaMethod
  open func getName() -> String
}
extension JavaClass<BluetoothHealthAppConfiguration> {
  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<BluetoothHealthAppConfiguration>!

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
