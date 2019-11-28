import 'package:tuple/tuple.dart';

import 'NotepadClient.dart';

enum BleInputProperty { Disabled, Indication }

class NotepadType {
  final NotepadClient _notepadClient;

  NotepadType(this._notepadClient);

  void configCharacteristics() {
    for (var serviceCharacteristic in _notepadClient.inputIndicationCharacteristics)
      configInputCharacteristic(serviceCharacteristic, BleInputProperty.Indication);
  }

  void configInputCharacteristic(Tuple2<String, String> serviceCharacteristic, BleInputProperty inputProperty) {
    print('configInputCharacteristic $serviceCharacteristic, $inputProperty');
  }
}
