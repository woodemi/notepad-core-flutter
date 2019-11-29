import 'dart:async';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import 'notepad_core_native.dart';

class BleInputProperty {
  static final disabled = BleInputProperty._('disabled');
  static final indication = BleInputProperty._('indication');

  final String value;

  BleInputProperty._(this.value);
}

class BleType {
  final tag = 'BleType';

  BleType() {
    message_client.setMessageHandler(handleMessage);
  }

  // FIXME Close
  final _characteristicConfigController = StreamController<String>();

  Future<void> setNotifiable(Tuple2<String, String> serviceCharacteristic, BleInputProperty bleInputProperty) async {
    method.invokeMethod('setNotifiable', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'bleInputProperty': bleInputProperty.value,
    }).then((_) => print('setNotifiable invokeMethod success'));
    // TODO Timeout
    await _characteristicConfigController.stream.any((c) => c == serviceCharacteristic.item2);
  }


  void writeValue(Tuple2<String, String> serviceCharacteristic, Uint8List value) {
    method.invokeMethod('writeValue', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'value': value,
    }).then((_) => print('writeValue invokeMethod success'));
  }

  // FIXME Close
  final _characteristicValueController = StreamController<Tuple2<String, Uint8List>>.broadcast();
  Stream<Tuple2<String, Uint8List>> get inputValueStream => _characteristicValueController.stream;

  Future<dynamic> handleMessage(dynamic message) {
    print('$tag handleMessage $message');
    if (message['characteristicConfig'] != null) {
      _characteristicConfigController.add(message['characteristicConfig']);
    } else if (message['characteristicValue'] != null) {
      var characteristicValue = message['characteristicValue'];
      _characteristicValueController.add(Tuple2(characteristicValue['characteristic'], characteristicValue['value']));
    }
  }
}