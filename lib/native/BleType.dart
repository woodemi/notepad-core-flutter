import 'dart:async';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import 'notepad_core_native.dart';

class BleInputProperty {
  static final disabled = BleInputProperty._('disabled');
  static final notification = BleInputProperty._('notification');
  static final indication = BleInputProperty._('indication');

  final String value;

  BleInputProperty._(this.value);
}

class BleOutputProperty {
  static final withResponse = BleOutputProperty._('withResponse');
  static final withoutResponse = BleOutputProperty._('withoutResponse');

  final String value;

  BleOutputProperty._(this.value);
}

class BleConnectionPriority {
  static final balanced = BleConnectionPriority._('balanced');
  static final high = BleConnectionPriority._('high');
  static final lowPower = BleConnectionPriority._('lowPower');

  final String value;

  BleConnectionPriority._(this.value);
}

class BleType {
  final tag = 'BleType';

  BleType() {
    message_client.setMessageHandler(handleMessage);
  }

  // FIXME Close
  final _characteristicConfigController = StreamController<String>.broadcast();

  Future<void> setNotifiable(Tuple2<String, String> serviceCharacteristic, BleInputProperty bleInputProperty) async {
    method.invokeMethod('setNotifiable', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'bleInputProperty': bleInputProperty.value,
    }).then((_) => print('setNotifiable invokeMethod success'));
    // TODO Timeout
    await _characteristicConfigController.stream.any((c) => c == serviceCharacteristic.item2);
  }

  // FIXME Close
  final _mtuConfigController = StreamController<int>.broadcast();

  Future<int> requestMtu(int expectedMtu) async {
    method.invokeMethod('requestMtu', {
      'expectedMtu': expectedMtu,
    }).then((_) => print('requestMtu invokeMethod success'));
    return await _mtuConfigController.stream.first;
  }

  void requestConnectionPriority(BleConnectionPriority bleConnectionPriority) {
    method.invokeMethod('requestConnectionPriority', {
      'bleConnectionPriority': bleConnectionPriority.value,
    }).then((_) => print('requestMtu invokeMethod success'));
  }

  void readValue(Tuple2<String, String> serviceCharacteristic) {
    method.invokeListMethod('readValue', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
    }).then((_) => print('readValue invokeMethod success'));
  }

  void writeValue(Tuple2<String, String> serviceCharacteristic, Uint8List value, BleOutputProperty bleOutputProperty) {
    method.invokeMethod('writeValue', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'value': value,
      'bleOutputProperty': bleOutputProperty.value,
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
      var value = Uint8List.fromList(characteristicValue['value']); // In case of _Uint8ArrayView
      _characteristicValueController.add(Tuple2(characteristicValue['characteristic'], value));
    } else if (message['mtuConfig'] != null) {
      _mtuConfigController.add(message['mtuConfig']);
    }
  }
}