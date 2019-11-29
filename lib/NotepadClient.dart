import 'package:tuple/tuple.dart';

import 'Notepad.dart';
import 'NotepadType.dart';

abstract class NotepadClient {
  Tuple2<String, String> get commandRequestCharacteristic;

  Tuple2<String, String> get commandResponseCharacteristic;

  Tuple2<String, String> get syncInputCharacteristic;

  List<Tuple2<String, String>> get inputIndicationCharacteristics;

  List<Tuple2<String, String>> get inputNotificationCharacteristics;

  NotepadType notepadType;

  Future<void> completeConnection(void awaitConfirm(bool));

  Future<String> getDeviceName();

  Future<void> setDeviceName(String name);

  Future<void> setMode(NotepadMode notepadMode);
}
