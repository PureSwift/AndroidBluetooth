// Auto-generated by Java-to-Swift wrapper generator.
import JavaIO
import JavaKit
import JavaRuntime

@JavaClass("android.bluetooth.BluetoothSocket", implements: Closeable.self)
open class BluetoothSocket: JavaObject {
  @JavaMethod
  open func getRemoteDevice() -> BluetoothDevice!

  @JavaMethod
  open func connect() throws

  @JavaMethod
  open func getOutputStream() throws -> OutputStream!

  @JavaMethod
  open func isConnected() -> Bool

  @JavaMethod
  open func getConnectionType() -> Int32

  @JavaMethod
  open func getMaxTransmitPacketSize() -> Int32

  @JavaMethod
  open func getMaxReceivePacketSize() -> Int32

  @JavaMethod
  open override func finalize() throws

  @JavaMethod
  open override func toString() -> String

  @JavaMethod
  open func close() throws

  @JavaMethod
  open func getInputStream() throws -> InputStream!
}
extension JavaClass<BluetoothSocket> {
  @JavaStaticField(isFinal: true)
  public var TYPE_L2CAP: Int32

  @JavaStaticField(isFinal: true)
  public var TYPE_RFCOMM: Int32

  @JavaStaticField(isFinal: true)
  public var TYPE_SCO: Int32
}
