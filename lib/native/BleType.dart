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
  void setNotifiable(Tuple2<String, String> serviceCharacteristic, BleInputProperty bleInputProperty) {
    method.invokeMethod('setNotifiable', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'bleInputProperty': bleInputProperty.value,
    }).then((_) => print('setNotifiable invokeMethod success'));
  }

  void writeValue(Tuple2<String, String> serviceCharacteristic, Uint8List value) {
    method.invokeMethod('writeValue', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'value': value,
    }).then((_) => print('writeValue invokeMethod success'));
  }
}