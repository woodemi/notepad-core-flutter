import 'dart:typed_data';

import 'package:flutter/foundation.dart';

const TAG_IMAGE = [0x00, 0x00];
const TAG_BITMAP = [0x00, 0xF0];
const TAG_CRC = [0x00, 0xF1];

class ImageTransmission {
  static const HEADER_LENGTH = 58;
  static const EMPTY_LENGTH = HEADER_LENGTH + 6 /*empty imageTagValue*/ + 8 /*crcTagValue*/;

  Uint8List _imageData;

  Uint8List get imageData => _imageData;

  Uint8List _crc;

  ImageTransmission.fromBytes(Uint8List bytes) {
    var totalSize = parseHeader(bytes.sublist(0, HEADER_LENGTH));
    var pendingData = bytes.sublist(HEADER_LENGTH);
    if (totalSize != HEADER_LENGTH + pendingData.length) throw AssertionError('Invalid totalSize');

    var longValues = scanLongTagValue(pendingData);
    _imageData = longValues.firstWhere((lv) => listEquals(lv.tag, TAG_IMAGE)).value;
    _crc = longValues.firstWhere((lv) => listEquals(lv.tag, TAG_CRC)).value;

    if (!listEquals(crc16(_imageData), _crc)) throw Exception('Data CRC fail');
  }

  /// +--------------------------------------------------------------------------------------------------------------------------------+
  /// |                                                             header                                                             |
  /// +----------+----------------+---------------+---------------+------------+----------+---------------+---------------+------------+
  /// | fileId   |  headerVersion |  headerLength |  fieldControl |  companyId |  imageId |  imageVersion |  headerString |  totalSize |
  /// |          |                |               |               |            |          |               |               |            |
  /// | 4 bytes  |  2 bytes       |  2 bytes      |  2 bytes      |  2 bytes   |  2 bytes |  8 bytes      |  32 bytes     |  4 bytes   |
  /// +----------+----------------+---------------+---------------+------------+----------+---------------+---------------+------------+
  int parseHeader(Uint8List bytes) {
    var byteData = bytes.buffer.asByteData();
    var position = 0;
    final fileId = bytes.sublist(position, position += 4);
    final headerVersion = bytes.sublist(position, position += 2);
    final headerLength = byteData.getUint16(position, Endian.little);
    position += 2;
    if (headerLength != HEADER_LENGTH) throw AssertionError('Invalid headerLength');

    final fieldControl = bytes.sublist(position, position += 2);
    final companyId = bytes.sublist(position, position += 2);
    final imageId = bytes.sublist(position, position += 2);
    final imageVersion = bytes.sublist(position, position += 8);
    final headerString = bytes.sublist(position, position += 32);
    return byteData.getUint32(position, Endian.little);
  }
}

Iterable<LongTagValue> scanLongTagValue(Uint8List bytes) sync* {
  var index = 0;
  var byteData = bytes.buffer.asByteData();
  while (index < bytes.length) {
    var tag = bytes.sublist(index, index += 2);
    var length = byteData.getUint32(index, Endian.little);
    index += 4;
    var value = bytes.sublist(index, index += length);
    yield LongTagValue(tag, value);
  }
}

class LongTagValue {
  final Uint8List tag;
  final Uint8List value;

  LongTagValue(this.tag, this.value) : assert(tag.length == 2);
}

Uint8List crc16(Uint8List bytes) {
  // CCITT
  const POLYNOMIAL = 0x1021;
  // XMODEM
  const INIT_VALUE = 0x0000;

  final bitRange = Iterable.generate(8);

  var crc = INIT_VALUE;
  for (var byte in bytes) {
    crc ^= (byte << 8);
    for (var i in bitRange) {
      crc = (crc & 0x8000) != 0 ? (crc << 1) ^ POLYNOMIAL : crc << 1;
    }
  }
  // FIXME setInt16 or setUint16
  var byteData = ByteData(2)..setInt16(0, crc, Endian.little);
  return byteData.buffer.asUint8List();
}
