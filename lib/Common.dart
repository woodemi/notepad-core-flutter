import 'package:flutter/foundation.dart';
import 'package:notepad_core/woodemi/WoodemiClient.dart';

import 'Notepad.dart';

bool support(NotepadScanResult scanResult) {
  return startWith(scanResult.manufacturerData, WOODEMI_PREFIX);
}

bool startWith<T>(List<T> src, List<T> prefix) =>
    src.length >= prefix.length &&
    listEquals(src.take(prefix.length).toList(), prefix);
