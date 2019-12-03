import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:notepad_core/NotepadClient.dart';
import 'package:notepad_core/woodemi/WoodemiClient.dart';

import 'Notepad.dart';

bool support(NotepadScanResult scanResult) {
  return startWith(scanResult.manufacturerData, WOODEMI_PREFIX);
}

NotepadClient create(NotepadScanResult scanResult) {
  if (startWith(scanResult.manufacturerData, WOODEMI_PREFIX))
    return WoodemiClient();
  else
    throw UnimplementedError();
}

bool startWith<T>(List<T> src, List<T> prefix) =>
    src.length >= prefix.length &&
    listEquals(src.take(prefix.length).toList(), prefix);

class AccessException implements Exception {
  static final Denied = AccessException._('Notepad claimed by other user');
  static final Unconfirmed = AccessException._('User does not confirm before timeout');

  final String message;

  AccessException._(this.message);
}

List<NotePenPointer> parseSyncPointer(Uint8List value) {
  var byteData = value.buffer.asByteData();
  return List.generate(value.length ~/ 6, (index) {
    return NotePenPointer(
        byteData.getUint16(index, Endian.little),
        byteData.getUint16(index + 2, Endian.little),
        -1,
        byteData.getUint16(index + 4, Endian.little),
    );
  });
}

Future<String> readUTF8Text(String path) => File(path).readAsString();