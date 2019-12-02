import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notepad_core/Common.dart';
import 'package:notepad_core/woodemi/FileRecord.dart';

import 'utils.dart';

void main() async {
  final testAssets = await findDirectoryPath('test/assets');

  test('FileRecord.fromLine', () {
    expect(FileRecord.fromLine('S01B0000736D6172745F6E6F74655F6672656572746F732E7372656304').tag,
        FileRecord.RECORD_TYPE_HEADER);
    expect(FileRecord.fromLine('S113280000000204B1B20200677D0000AB95000035').tag,
        FileRecord.RECORD_TYPE_DATA_1);
    expect(FileRecord.fromLine('S21401000013F86420F5F73DFBFFF741FF13BD000031').tag,
        FileRecord.RECORD_TYPE_DATA_2);
    expect(FileRecord.fromLine('S80402B72D15').tag,
        FileRecord.RECORD_TYPE_TERMINATION);
  });

  test('parseUpgradeFile', () async {
    var src = await parseUpgradeFile('$testAssets/1_1_1.srec');
    var dst = hex.decode(await readUTF8Text('$testAssets/1_1_1.srec.hex'));
    expect(src, dst);
  });
}