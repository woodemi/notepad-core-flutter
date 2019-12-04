import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notepad_core/Notepad.dart';
import 'package:notepad_core/woodemi/WoodemiClient.dart';

void main() {
  var woodemiClient = WoodemiClient();

  test('parseSyncData', () {
    var bytes = Uint8List.fromList(hex.decode('4c21a8200000ef20a82000009a2066200000'));
    var pointers = woodemiClient.parseSyncData(bytes);
    expect(pointers, [
      NotePenPointer(8524, 8360, -1, 0),
      NotePenPointer(8431, 8360, -1, 0),
      NotePenPointer(8346, 8294, -1, 0),
    ]);
  });
}