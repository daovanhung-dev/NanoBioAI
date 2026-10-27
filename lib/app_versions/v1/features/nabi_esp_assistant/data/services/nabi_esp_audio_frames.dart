import 'dart:typed_data';

/// Framing helpers for the XiaoZhi WebSocket v3 binary audio payload.
///
/// Byte 0 identifies audio (0), byte 1 is reserved, bytes 2-3 contain the
/// Opus packet length in network byte order, followed by the packet.
abstract final class NabiEspAudioFrames {
  static const headerLength = 4;
  static const maximumOpusPacketLength = 1275;

  static Uint8List decode(Uint8List frame) {
    if (frame.length < headerLength || frame[0] != 0) {
      throw const FormatException('Invalid XiaoZhi audio frame.');
    }
    final packetLength = ByteData.sublistView(frame).getUint16(2, Endian.big);
    if (packetLength == 0 ||
        packetLength > maximumOpusPacketLength ||
        packetLength != frame.length - headerLength) {
      throw const FormatException('Invalid XiaoZhi Opus packet length.');
    }
    return Uint8List.sublistView(frame, headerLength);
  }

  static Uint8List encode(Uint8List packet) {
    if (packet.isEmpty || packet.length > maximumOpusPacketLength) {
      throw const FormatException('Invalid Opus packet length.');
    }
    final frame = Uint8List(headerLength + packet.length);
    frame[0] = 0;
    frame[1] = 0;
    ByteData.sublistView(frame).setUint16(2, packet.length, Endian.big);
    frame.setRange(headerLength, frame.length, packet);
    return frame;
  }
}

/// Constant-time token comparison for the small, fixed-size session secret.
bool nabiEspTokensMatch(String expected, String supplied) {
  final left = Uint8List.fromList(expected.codeUnits);
  final right = Uint8List.fromList(supplied.codeUnits);
  var mismatch = left.length ^ right.length;
  final length = left.length > right.length ? left.length : right.length;
  for (var index = 0; index < length; index++) {
    mismatch |=
        (index < left.length ? left[index] : 0) ^
        (index < right.length ? right[index] : 0);
  }
  return mismatch == 0;
}

Int16List nabiEspResample(Int16List input, int inputRate, int outputRate) {
  if (input.isEmpty || inputRate <= 0 || outputRate <= 0) {
    throw ArgumentError('PCM data and sample rates must be positive.');
  }
  if (inputRate == outputRate) return input;
  final outputLength = (input.length * outputRate / inputRate).floor();
  final output = Int16List(outputLength);
  for (var index = 0; index < outputLength; index++) {
    final position = index * inputRate / outputRate;
    final first = position.floor();
    final second = first + 1 < input.length ? first + 1 : input.length - 1;
    final fraction = position - first;
    output[index] = (input[first] * (1 - fraction) + input[second] * fraction)
        .round()
        .clamp(-32768, 32767)
        .toInt();
  }
  return output;
}
