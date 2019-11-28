import 'package:tuple/tuple.dart';

abstract class NotepadClient {
  Tuple2<String, String> get commandResponseCharacteristic;

  List<Tuple2<String, String>> get inputIndicationCharacteristics;
}
