// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaKitCollection
import JavaRuntime

@JavaClass("android.bluetooth.le.TransportDiscoveryData", implements: Parcelable.self)
open class TransportDiscoveryData: JavaObject {
  @JavaMethod
  @_nonoverride public convenience init(_ arg0: Int32, _ arg1: List<TransportBlock>?, environment: JNIEnvironment? = nil)

  @JavaMethod
  @_nonoverride public convenience init(_ arg0: [Int8], environment: JNIEnvironment? = nil)

  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func getTransportBlocks() -> List<TransportBlock>!

  @JavaMethod
  open func totalBytes() -> Int32

  @JavaMethod
  open func getTransportDataType() -> Int32

  @JavaMethod
  open override func equals(_ arg0: JavaObject?) -> Bool

  @JavaMethod
  open override func toString() -> String

  @JavaMethod
  open override func hashCode() -> Int32

  @JavaMethod
  open func toByteArray() -> [Int8]
}
extension JavaClass<TransportDiscoveryData> {
  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<TransportDiscoveryData>!

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
