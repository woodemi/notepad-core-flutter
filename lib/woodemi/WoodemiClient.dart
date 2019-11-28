import 'package:notepad_core/NotepadClient.dart';
import 'package:tuple/tuple.dart';

const SUFFIX = 'BA5E-F4EE-5CA1-EB1E5E4B1CE0';

const SERV__COMMAND = '57444D01-$SUFFIX';
const CHAR__COMMAND_REQUEST = '57444E02-$SUFFIX';
const CHAR__COMMAND_RESPONSE = CHAR__COMMAND_REQUEST;

const WOODEMI_PREFIX = [0x57, 0x44, 0x4d]; // 'WDM'

class WoodemiClient extends NotepadClient {
  @override
  Tuple2<String, String> get commandResponseCharacteristic => const Tuple2(SERV__COMMAND, CHAR__COMMAND_RESPONSE);

  @override
  List<Tuple2<String, String>> get inputIndicationCharacteristics => [
    commandResponseCharacteristic,
  ];
}
