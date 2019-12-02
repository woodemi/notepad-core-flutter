import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:tuple/tuple.dart';

import 'NotepadClient.dart';
import 'native/BleType.dart';
import 'src/NotepadCommand.dart';

const GATT_HEADER_LENGTH = 3;

class NotepadType {
  final NotepadClient _notepadClient;

  final _bleType = BleType();

  NotepadType(this._notepadClient) {
    _notepadClient.notepadType = this;
  }

  Future<void> configCharacteristics() async {
    for (var serviceCharacteristic in _notepadClient.inputIndicationCharacteristics) {
      print('configInputCharacteristic $serviceCharacteristic, indication');
      await _bleType.setNotifiable(serviceCharacteristic, BleInputProperty.indication);
    }
    for (var serviceCharacteristic in _notepadClient.inputNotificationCharacteristics) {
      print('configInputCharacteristic $serviceCharacteristic, notification');
      await _bleType.setNotifiable(serviceCharacteristic, BleInputProperty.notification);
    }
  }

  int mtu;

  Future<void> configMtu(int expectedMtu) async {
    mtu = await _bleType.requestMtu(expectedMtu) - GATT_HEADER_LENGTH;
  }

  void configConnectionPriority(BleConnectionPriority bleConnectionPriority) {
    _bleType.requestConnectionPriority(bleConnectionPriority);
  }

  void sendRequestAsync(String messageHead, Tuple2<String, String> serviceCharacteristic, Uint8List request) async {
    _bleType.writeValue(serviceCharacteristic, request);
    print('on${messageHead}Send: ${hex.encode(request)}');
  }

  Stream<Uint8List> receiveValue(Tuple2<String, String> serviceCharacteristic) =>
      _bleType.inputValueStream.where((cv) {
        return cv.item1 == serviceCharacteristic.item2 || '0000${cv.item1}-$GSS_SUFFIX' == serviceCharacteristic.item2;
      }).map((cv) => cv.item2);

  Future<Uint8List> receiveResponseAsync(String messageHead, Tuple2<String, String> serviceCharacteristic, Predicate intercept) async {
    var response = await receiveValue(serviceCharacteristic).firstWhere(intercept);
    print('on${messageHead}Receive: ${hex.encode(response)}');
    return response;
  }

  Future<T> fetchProperty<T>(Tuple2<String, String> serviceCharacteristic, Handle<T> handle) async {
    _bleType.readValue(serviceCharacteristic);
    var value = await receiveResponseAsync('Property', serviceCharacteristic, (value) => true);
    return handle(value);
  }

  Future<T> executeCommand<T>(NotepadCommand<T> command) async {
    await sendRequestAsync('Command', _notepadClient.commandRequestCharacteristic, command.request);
    var response = await receiveResponseAsync('Command', _notepadClient.commandResponseCharacteristic, command.intercept);
    return command.handle(response);
  }

  Stream<Uint8List> receiveSyncInput() => receiveValue(_notepadClient.syncInputCharacteristic).map((value) {
    print('onSyncInputReceive ${hex.encode(value)}');
    return value;
  });

  Future<T> executeFileInputControl<T>(NotepadCommand<T> command) async {
    await sendRequestAsync('FileInputControl', _notepadClient.fileInputControlRequestCharacteristic, command.request);
    var response = await receiveResponseAsync('FileInputControl', _notepadClient.fileInputControlResponseCharacteristic, command.intercept);
    return command.handle(response);
  }

  Stream<Uint8List> receiveFileInput() => receiveValue(_notepadClient.fileInputCharacteristic).map((value) {
    print('onFileInputReceive: ${hex.encode(value)}');
    return value;
  });
}
