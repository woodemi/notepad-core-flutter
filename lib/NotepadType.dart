import 'package:tuple/tuple.dart';

import 'NotepadClient.dart';
import 'native/BleType.dart';

class NotepadType {
  final NotepadClient _notepadClient;

  final _bleType = BleType();

  NotepadType(this._notepadClient);

  void configCharacteristics() {
    for (var serviceCharacteristic in _notepadClient.inputIndicationCharacteristics)
      configInputCharacteristic(serviceCharacteristic, BleInputProperty.indication);
  }

  void configInputCharacteristic(Tuple2<String, String> serviceCharacteristic, BleInputProperty inputProperty) {
    print('configInputCharacteristic $serviceCharacteristic, $inputProperty');
    _bleType.setNotifiable(serviceCharacteristic, inputProperty);
  }
}
