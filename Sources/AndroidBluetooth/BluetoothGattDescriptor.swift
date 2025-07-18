// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaRuntime
import JavaUtil

@JavaClass("android.bluetooth.BluetoothGattDescriptor", implements: Parcelable.self)
open class BluetoothGattDescriptor: JavaObject {
  @JavaMethod
  @_nonoverride public convenience init(_ arg0: UUID?, _ arg1: Int32, environment: JNIEnvironment? = nil)

  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func getUuid() -> UUID!

  @JavaMethod
  open func getCharacteristic() -> BluetoothGattCharacteristic!

  @JavaMethod
  open func getValue() -> [Int8]

  @JavaMethod
  open func getPermissions() -> Int32

  @JavaMethod
  open func setValue(_ arg0: [Int8]) -> Bool
}
extension JavaClass<BluetoothGattDescriptor> {
  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<BluetoothGattDescriptor>!

  @JavaStaticField(isFinal: true)
  public var DISABLE_NOTIFICATION_VALUE: [Int8]

  @JavaStaticField(isFinal: true)
  public var ENABLE_INDICATION_VALUE: [Int8]

  @JavaStaticField(isFinal: true)
  public var ENABLE_NOTIFICATION_VALUE: [Int8]

  @JavaStaticField(isFinal: true)
  public var PERMISSION_READ: Int32

  @JavaStaticField(isFinal: true)
  public var PERMISSION_READ_ENCRYPTED: Int32

  @JavaStaticField(isFinal: true)
  public var PERMISSION_READ_ENCRYPTED_MITM: Int32

  @JavaStaticField(isFinal: true)
  public var PERMISSION_WRITE: Int32

  @JavaStaticField(isFinal: true)
  public var PERMISSION_WRITE_ENCRYPTED: Int32

  @JavaStaticField(isFinal: true)
  public var PERMISSION_WRITE_ENCRYPTED_MITM: Int32

  @JavaStaticField(isFinal: true)
  public var PERMISSION_WRITE_SIGNED: Int32

  @JavaStaticField(isFinal: true)
  public var PERMISSION_WRITE_SIGNED_MITM: Int32

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
