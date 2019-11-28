import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:tuple/tuple.dart';

import 'NotepadClient.dart';
import 'native/BleType.dart';
import 'src/NotepadCommand.dart';

class NotepadType {
  final NotepadClient _notepadClient;

  final _bleType = BleType();

  NotepadType(this._notepadClient) {
    _notepadClient.notepadType = this;
  }

  void configCharacteristics() {
    for (var serviceCharacteristic in _notepadClient.inputIndicationCharacteristics)
      configInputCharacteristic(serviceCharacteristic, BleInputProperty.indication);
  }

  void configInputCharacteristic(Tuple2<String, String> serviceCharacteristic, BleInputProperty inputProperty) {
    print('configInputCharacteristic $serviceCharacteristic, $inputProperty');
    _bleType.setNotifiable(serviceCharacteristic, inputProperty);
  }

  void sendRequestAsync(String messageHead, Tuple2<String, String> serviceCharacteristic, Uint8List request) async {
    _bleType.writeValue(serviceCharacteristic, request);
    print('on${messageHead}Send: ${hex.encode(request)}');
  }

  Future<Uint8List> receiveResponseAsync(String messageHead, Tuple2<String, String> commandResponseCharacteristic, Predicate intercept) async {
    // TODO
    var response = Uint8List.fromList([0, 0]);
    print('on${messageHead}Receive: ${hex.encode(response)}');
    return response;
  }

  Future<T> executeCommand<T>(NotepadCommand<T> command) async {
    await sendRequestAsync('Command', _notepadClient.commandRequestCharacteristic, command.request);
    var response = await receiveResponseAsync('Command', _notepadClient.commandResponseCharacteristic, command.intercept);
    return command.handle(response);
  }
}
