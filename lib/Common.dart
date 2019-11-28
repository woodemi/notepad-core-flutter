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
