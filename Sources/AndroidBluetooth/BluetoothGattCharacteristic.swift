// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaKitCollection
import JavaRuntime
import JavaUtil

@JavaClass("android.bluetooth.BluetoothGattCharacteristic", implements: Parcelable.self)
open class BluetoothGattCharacteristic: JavaObject {
  @JavaMethod
  @_nonoverride public convenience init(_ arg0: UUID?, _ arg1: Int32, _ arg2: Int32, environment: JNIEnvironment? = nil)

  @JavaMethod
  open func addDescriptor(_ arg0: BluetoothGattDescriptor?) -> Bool

  @JavaMethod
  open func getWriteType() -> Int32

  @JavaMethod
  open func setWriteType(_ arg0: Int32)

  @JavaMethod
  open func getIntValue(_ arg0: Int32, _ arg1: Int32) -> JavaInteger!

  @JavaMethod
  open func getFloatValue(_ arg0: Int32, _ arg1: Int32) -> JavaFloat!

  @JavaMethod
  open func getStringValue(_ arg0: Int32) -> String

  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func getDescriptors() -> List<BluetoothGattDescriptor>!

  @JavaMethod
  open func getService() -> BluetoothGattService!

  @JavaMethod
  open func getUuid() -> UUID!

  @JavaMethod
  open func getInstanceId() -> Int32

  @JavaMethod
  open func getValue() -> [Int8]

  @JavaMethod
  open func getDescriptor(_ arg0: UUID?) -> BluetoothGattDescriptor!

  @JavaMethod
  open func getProperties() -> Int32

  @JavaMethod
  open func getPermissions() -> Int32

  @JavaMethod
  open func setValue(_ arg0: String) -> Bool

  @JavaMethod
  open func setValue(_ arg0: [Int8]) -> Bool

  @JavaMethod
  open func setValue(_ arg0: Int32, _ arg1: Int32, _ arg2: Int32, _ arg3: Int32) -> Bool

  @JavaMethod
  open func setValue(_ arg0: Int32, _ arg1: Int32, _ arg2: Int32) -> Bool
}
extension JavaClass<BluetoothGattCharacteristic> {
  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<BluetoothGattCharacteristic>!

  @JavaStaticField(isFinal: true)
  public var FORMAT_FLOAT: Int32

  @JavaStaticField(isFinal: true)
  public var FORMAT_SFLOAT: Int32

  @JavaStaticField(isFinal: true)
  public var FORMAT_SINT16: Int32

  @JavaStaticField(isFinal: true)
  public var FORMAT_SINT32: Int32

  @JavaStaticField(isFinal: true)
  public var FORMAT_SINT8: Int32

  @JavaStaticField(isFinal: true)
  public var FORMAT_UINT16: Int32

  @JavaStaticField(isFinal: true)
  public var FORMAT_UINT32: Int32

  @JavaStaticField(isFinal: true)
  public var FORMAT_UINT8: Int32

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
  public var PROPERTY_BROADCAST: Int32

  @JavaStaticField(isFinal: true)
  public var PROPERTY_EXTENDED_PROPS: Int32

  @JavaStaticField(isFinal: true)
  public var PROPERTY_INDICATE: Int32

  @JavaStaticField(isFinal: true)
  public var PROPERTY_NOTIFY: Int32

  @JavaStaticField(isFinal: true)
  public var PROPERTY_READ: Int32

  @JavaStaticField(isFinal: true)
  public var PROPERTY_SIGNED_WRITE: Int32

  @JavaStaticField(isFinal: true)
  public var PROPERTY_WRITE: Int32

  @JavaStaticField(isFinal: true)
  public var PROPERTY_WRITE_NO_RESPONSE: Int32

  @JavaStaticField(isFinal: true)
  public var WRITE_TYPE_DEFAULT: Int32

  @JavaStaticField(isFinal: true)
  public var WRITE_TYPE_NO_RESPONSE: Int32

  @JavaStaticField(isFinal: true)
  public var WRITE_TYPE_SIGNED: Int32

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
