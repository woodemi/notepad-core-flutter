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

  test('parseMemo', () {
    var bytesStr = '48130000ffffd520021c3600d5201a1cdf00d5201a1cfa01de200f1cff01e420031cff01ec20f51bff011421c61bff012421b61bff013421a81bff0144219c1bff015421911bff016421881bff017321881bff018521881bff019821881bff01ad21881bff01c621931bff01e121a01bff01ff21b21bff011e22c71bff014022e31bff016422051cff018a22291cff01b3224f1cff01dc22721cff010523931cff012b23af1cff01e123991cff01';
    var bytes = Uint8List.fromList(hex.decode(bytesStr));
    var createTime = 4936 + SAMPLE_INTERVAL_MS; //  48130000ffff
    var pointers = woodemiClient.parseMemo(bytes, createTime).toList();
    expect(bytesStr.length / 12 - 1, pointers.length);
    expect(pointers, [
      NotePenPointer(8405, 7170, createTime + SAMPLE_INTERVAL_MS * 0, 54),
      NotePenPointer(8405, 7194, createTime + SAMPLE_INTERVAL_MS * 1, 223),
      NotePenPointer(8405, 7194, createTime + SAMPLE_INTERVAL_MS * 2, 506),
      NotePenPointer(8414, 7183, createTime + SAMPLE_INTERVAL_MS * 3, 511),
      NotePenPointer(8420, 7171, createTime + SAMPLE_INTERVAL_MS * 4, 511),
      NotePenPointer(8428, 7157, createTime + SAMPLE_INTERVAL_MS * 5, 511),
      NotePenPointer(8468, 7110, createTime + SAMPLE_INTERVAL_MS * 6, 511),
      NotePenPointer(8484, 7094, createTime + SAMPLE_INTERVAL_MS * 7, 511),
      NotePenPointer(8500, 7080, createTime + SAMPLE_INTERVAL_MS * 8, 511),
      NotePenPointer(8516, 7068, createTime + SAMPLE_INTERVAL_MS * 9, 511),
      NotePenPointer(8532, 7057, createTime + SAMPLE_INTERVAL_MS * 10, 511),
      NotePenPointer(8548, 7048, createTime + SAMPLE_INTERVAL_MS * 11, 511),
      NotePenPointer(8563, 7048, createTime + SAMPLE_INTERVAL_MS * 12, 511),
      NotePenPointer(8581, 7048, createTime + SAMPLE_INTERVAL_MS * 13, 511),
      NotePenPointer(8600, 7048, createTime + SAMPLE_INTERVAL_MS * 14, 511),
      NotePenPointer(8621, 7048, createTime + SAMPLE_INTERVAL_MS * 15, 511),
      NotePenPointer(8646, 7059, createTime + SAMPLE_INTERVAL_MS * 16, 511),
      NotePenPointer(8673, 7072, createTime + SAMPLE_INTERVAL_MS * 17, 511),
      NotePenPointer(8703, 7090, createTime + SAMPLE_INTERVAL_MS * 18, 511),
      NotePenPointer(8734, 7111, createTime + SAMPLE_INTERVAL_MS * 19, 511),
      NotePenPointer(8768, 7139, createTime + SAMPLE_INTERVAL_MS * 20, 511),
      NotePenPointer(8804, 7173, createTime + SAMPLE_INTERVAL_MS * 21, 511),
      NotePenPointer(8842, 7209, createTime + SAMPLE_INTERVAL_MS * 22, 511),
      NotePenPointer(8883, 7247, createTime + SAMPLE_INTERVAL_MS * 23, 511),
      NotePenPointer(8924, 7282, createTime + SAMPLE_INTERVAL_MS * 24, 511),
      NotePenPointer(8965, 7315, createTime + SAMPLE_INTERVAL_MS * 25, 511),
      NotePenPointer(9003, 7343, createTime + SAMPLE_INTERVAL_MS * 26, 511),
      NotePenPointer(9185, 7321, createTime + SAMPLE_INTERVAL_MS * 27, 511),
    ]);
  });
}
