import 'dart:typed_data';

import '../Common.dart';
import '../Notepad.dart';
import '../NotepadClient.dart';
import '../NotepadType.dart';
import 'notepad_core_native.dart';

typedef ConnectionChangeHandler = void Function(NotepadClient client, String state);

final notepadConnector = NotepadConnector._();

class NotepadConnector {
  final tag = 'NotepadConnector';

  NotepadConnector._() {
    message.setMessageHandler(_handleMessage);
  }

  void startScan() {
    method
        .invokeMethod('startScan')
        .then((_) => print('startScan invokeMethod success'));
  }

  void stopScan() {
    method
        .invokeMethod('stopScan')
        .then((_) => print('stopScan invokeMethod success'));
  }

  final Stream<NotepadScanResult> scanResultStream = event_scanResult
      .receiveBroadcastStream({'name': 'scanResult'})
      .map((item) => NotepadScanResult.fromMap(item))
      .where(support);

  NotepadClient _notepadClient;
  NotepadType _notepadType;

  void connect(NotepadScanResult scanResult, [Uint8List authToken]) {
    _notepadClient = create(scanResult);
    _notepadClient.setAuthToken(authToken);
    _notepadType = NotepadType(_notepadClient);
    method.invokeMethod('connect', {
      'deviceId': scanResult.deviceId,
    }).then((_) => print('connect invokeMethod success'));
    if (_connectionChangeHandler != null)
      _connectionChangeHandler(_notepadClient, 'Connecting');
  }

  void disconnect() {
    _notepadClient = null;
    _notepadType = null;
    method.invokeMethod('disconnect')
        .then((_) => print('disconnect invokeMethod success'));
  }

  ConnectionChangeHandler _connectionChangeHandler;

  void setConnectionChangeHandler(ConnectionChangeHandler handler) {
    _connectionChangeHandler = handler;
  }

  Future<dynamic> _handleMessage(dynamic message) async {
    print('$tag handleMessage $message');
    if (message['ConnectionState'] != null) {
      if (message['ConnectionState'] == 'Connected')
        method.invokeMethod('discoverServices').then((_) =>
            print('discoverServices invokeMethod success'));
      else
        if (_connectionChangeHandler != null) _connectionChangeHandler(_notepadClient, message['ConnectionState']);
    } else if (message['ServiceState'] != null) {
      if (message['ServiceState'] == 'Discovered')
        _onServicesDiscovered();
    }
  }

  void _onServicesDiscovered() async {
    try {
      await _notepadType.configCharacteristics();
      await _notepadClient.completeConnection((awaitConfrim) {
        if (_connectionChangeHandler != null)
          _connectionChangeHandler(_notepadClient, 'AwaitConfirm');
      });
      if (_connectionChangeHandler != null)
        _connectionChangeHandler(_notepadClient, 'Connected');
    } on AccessException {
      if (_connectionChangeHandler != null)
        _connectionChangeHandler(_notepadClient, 'Disconnected');
    }
  }
}