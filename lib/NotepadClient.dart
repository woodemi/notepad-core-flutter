import 'package:tuple/tuple.dart';

import 'NotepadType.dart';

abstract class NotepadClient {
  Tuple2<String, String> get commandRequestCharacteristic;

  Tuple2<String, String> get commandResponseCharacteristic;

  List<Tuple2<String, String>> get inputIndicationCharacteristics;

  NotepadType notepadType;

  void completeConnection();
}
