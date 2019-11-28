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
    characteristicConfig.setMessageHandler(handleMessage);
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

  Future<dynamic> handleMessage(dynamic message) {
    print('$tag handleMessage $message');
    _characteristicConfigController.add(message);
  }
}