// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaKitCollection
import JavaRuntime
import JavaUtil

@JavaClass("android.bluetooth.BluetoothGattService", implements: Parcelable.self)
open class BluetoothGattService: JavaObject {
  @JavaMethod
  @_nonoverride public convenience init(_ arg0: UUID?, _ arg1: Int32, environment: JNIEnvironment? = nil)

  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func addService(_ arg0: BluetoothGattService?) -> Bool

  @JavaMethod
  open func addCharacteristic(_ arg0: BluetoothGattCharacteristic?) -> Bool

  @JavaMethod
  open func getUuid() -> UUID!

  @JavaMethod
  open func getInstanceId() -> Int32

  @JavaMethod
  open func getCharacteristics() -> List<BluetoothGattCharacteristic>!

  @JavaMethod
  open func getCharacteristic(_ arg0: UUID?) -> BluetoothGattCharacteristic!

  @JavaMethod
  open func getIncludedServices() -> List<BluetoothGattService>!

  @JavaMethod
  internal func getType() -> Int32

    public var type: ServiceType {
        .init(rawValue: getType())!
    }
}
extension JavaClass<BluetoothGattService> {
  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<BluetoothGattService>!

  @JavaStaticField(isFinal: true)
  public var SERVICE_TYPE_PRIMARY: Int32

  @JavaStaticField(isFinal: true)
  public var SERVICE_TYPE_SECONDARY: Int32

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
