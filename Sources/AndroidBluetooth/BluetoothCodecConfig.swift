// Auto-generated by Java-to-Swift wrapper generator.
import AndroidOS
import JavaKit
import JavaRuntime

@JavaClass("android.bluetooth.BluetoothCodecConfig", implements: Parcelable.self)
open class BluetoothCodecConfig: JavaObject {
  @JavaMethod
  open func describeContents() -> Int32

  @JavaMethod
  open func writeToParcel(_ arg0: Parcel?, _ arg1: Int32)

  @JavaMethod
  open func getCodecType() -> Int32

  @JavaMethod
  open func isMandatoryCodec() -> Bool

  @JavaMethod
  open func getCodecPriority() -> Int32

  @JavaMethod
  open func getSampleRate() -> Int32

  @JavaMethod
  open func getBitsPerSample() -> Int32

  @JavaMethod
  open func getChannelMode() -> Int32

  @JavaMethod
  open func getCodecSpecific1() -> Int64

  @JavaMethod
  open func getCodecSpecific2() -> Int64

  @JavaMethod
  open func getCodecSpecific3() -> Int64

  @JavaMethod
  open func getCodecSpecific4() -> Int64

  @JavaMethod
  open func getExtendedCodecType() -> BluetoothCodecType!

  @JavaMethod
  open override func equals(_ arg0: JavaObject?) -> Bool

  @JavaMethod
  open override func toString() -> String

  @JavaMethod
  open override func hashCode() -> Int32
}
extension JavaClass<BluetoothCodecConfig> {
  @JavaStaticField(isFinal: true)
  public var BITS_PER_SAMPLE_16: Int32

  @JavaStaticField(isFinal: true)
  public var BITS_PER_SAMPLE_24: Int32

  @JavaStaticField(isFinal: true)
  public var BITS_PER_SAMPLE_32: Int32

  @JavaStaticField(isFinal: true)
  public var BITS_PER_SAMPLE_NONE: Int32

  @JavaStaticField(isFinal: true)
  public var CHANNEL_MODE_MONO: Int32

  @JavaStaticField(isFinal: true)
  public var CHANNEL_MODE_NONE: Int32

  @JavaStaticField(isFinal: true)
  public var CHANNEL_MODE_STEREO: Int32

  @JavaStaticField(isFinal: true)
  public var CODEC_PRIORITY_DEFAULT: Int32

  @JavaStaticField(isFinal: true)
  public var CODEC_PRIORITY_DISABLED: Int32

  @JavaStaticField(isFinal: true)
  public var CODEC_PRIORITY_HIGHEST: Int32

  @JavaStaticField(isFinal: true)
  public var CREATOR: Parcelable.Creator<BluetoothCodecConfig>!

  @JavaStaticField(isFinal: true)
  public var SAMPLE_RATE_176400: Int32

  @JavaStaticField(isFinal: true)
  public var SAMPLE_RATE_192000: Int32

  @JavaStaticField(isFinal: true)
  public var SAMPLE_RATE_44100: Int32

  @JavaStaticField(isFinal: true)
  public var SAMPLE_RATE_48000: Int32

  @JavaStaticField(isFinal: true)
  public var SAMPLE_RATE_88200: Int32

  @JavaStaticField(isFinal: true)
  public var SAMPLE_RATE_96000: Int32

  @JavaStaticField(isFinal: true)
  public var SAMPLE_RATE_NONE: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_AAC: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_APTX: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_APTX_HD: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_INVALID: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_LC3: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_LDAC: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_OPUS: Int32

  @JavaStaticField(isFinal: true)
  public var SOURCE_CODEC_TYPE_SBC: Int32

  @JavaStaticField(isFinal: true)
  public var CONTENTS_FILE_DESCRIPTOR: Int32

  @JavaStaticField(isFinal: true)
  public var PARCELABLE_WRITE_RETURN_VALUE: Int32
}
