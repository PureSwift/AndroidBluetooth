// Auto-generated by Java-to-Swift wrapper generator.
import JavaKit
import JavaKitCollection
import JavaRuntime
import JavaUtil

@JavaClass("android.bluetooth.BluetoothGatt", implements: BluetoothProfile.self)
open class BluetoothGatt: JavaObject {
  @JavaMethod
  open func getConnectionState(_ arg0: BluetoothDevice?) -> Int32

  @JavaMethod
  open func disconnect()

  @JavaMethod
  open func connect() -> Bool

  @JavaMethod
  open func setPreferredPhy(_ arg0: Int32, _ arg1: Int32, _ arg2: Int32)

  @JavaMethod
  open func readPhy()

  @JavaMethod
  open func getDevice() -> BluetoothDevice!

  @JavaMethod
  open func discoverServices() -> Bool

  @JavaMethod
  open func getServices() -> List<BluetoothGattService>!

  @JavaMethod
  open func getService(_ arg0: UUID?) -> BluetoothGattService!

  @JavaMethod
  open func readCharacteristic(_ arg0: BluetoothGattCharacteristic?) -> Bool

  @JavaMethod
  open func readDescriptor(_ arg0: BluetoothGattDescriptor?) -> Bool

  @JavaMethod
  open func writeDescriptor(_ arg0: BluetoothGattDescriptor?, _ arg1: [Int8]) -> Int32

  @JavaMethod
  open func writeDescriptor(_ arg0: BluetoothGattDescriptor?) -> Bool

  @JavaMethod
  open func beginReliableWrite() -> Bool

  @JavaMethod
  open func abortReliableWrite(_ arg0: BluetoothDevice?)

  @JavaMethod
  open func abortReliableWrite()

  @JavaMethod
  open func readRemoteRssi() -> Bool

  @JavaMethod
  open func requestMtu(_ arg0: Int32) -> Bool

  @JavaMethod
  open func getConnectedDevices() -> List<BluetoothDevice>!

  @JavaMethod
  open func getDevicesMatchingConnectionStates(_ arg0: [Int32]) -> List<BluetoothDevice>!

  @JavaMethod
  open func writeCharacteristic(_ arg0: BluetoothGattCharacteristic?, _ arg1: [Int8], _ arg2: Int32) -> Int32

  @JavaMethod
  open func writeCharacteristic(_ arg0: BluetoothGattCharacteristic?) -> Bool

  @JavaMethod
  open func executeReliableWrite() -> Bool

  @JavaMethod
  open func setCharacteristicNotification(_ arg0: BluetoothGattCharacteristic?, _ arg1: Bool) -> Bool

  @JavaMethod
  open func requestConnectionPriority(_ arg0: Int32) -> Bool

  @JavaMethod
  open func close()
}
extension JavaClass<BluetoothGatt> {
  @JavaStaticField(isFinal: true)
  public var CONNECTION_PRIORITY_BALANCED: Int32

  @JavaStaticField(isFinal: true)
  public var CONNECTION_PRIORITY_DCK: Int32

  @JavaStaticField(isFinal: true)
  public var CONNECTION_PRIORITY_HIGH: Int32

  @JavaStaticField(isFinal: true)
  public var CONNECTION_PRIORITY_LOW_POWER: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_CONNECTION_CONGESTED: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_CONNECTION_TIMEOUT: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_FAILURE: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_INSUFFICIENT_AUTHENTICATION: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_INSUFFICIENT_AUTHORIZATION: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_INSUFFICIENT_ENCRYPTION: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_INVALID_ATTRIBUTE_LENGTH: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_INVALID_OFFSET: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_READ_NOT_PERMITTED: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_REQUEST_NOT_SUPPORTED: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_SUCCESS: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_WRITE_NOT_PERMITTED: Int32

  @JavaStaticField(isFinal: true)
  public var A2DP: Int32

  @JavaStaticField(isFinal: true)
  public var CSIP_SET_COORDINATOR: Int32

  @JavaStaticField(isFinal: true)
  public var EXTRA_PREVIOUS_STATE: String

  @JavaStaticField(isFinal: true)
  public var EXTRA_STATE: String

  @JavaStaticField(isFinal: true)
  public var GATT: Int32

  @JavaStaticField(isFinal: true)
  public var GATT_SERVER: Int32

  @JavaStaticField(isFinal: true)
  public var HAP_CLIENT: Int32

  @JavaStaticField(isFinal: true)
  public var HEADSET: Int32

  @JavaStaticField(isFinal: true)
  public var HEALTH: Int32

  @JavaStaticField(isFinal: true)
  public var HEARING_AID: Int32

  @JavaStaticField(isFinal: true)
  public var HID_DEVICE: Int32

  @JavaStaticField(isFinal: true)
  public var LE_AUDIO: Int32

  @JavaStaticField(isFinal: true)
  public var SAP: Int32

  @JavaStaticField(isFinal: true)
  public var STATE_CONNECTED: Int32

  @JavaStaticField(isFinal: true)
  public var STATE_CONNECTING: Int32

  @JavaStaticField(isFinal: true)
  public var STATE_DISCONNECTED: Int32

  @JavaStaticField(isFinal: true)
  public var STATE_DISCONNECTING: Int32
}
