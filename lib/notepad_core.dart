import 'package:flutter/services.dart';

import 'Common.dart';
import 'Notepad.dart';

export 'Notepad.dart';

const _method = const MethodChannel('notepad_core/method');
const _event_scanResult = const EventChannel('notepad_core/event.scanResult');
const _message = BasicMessageChannel(
    'notepad_core/message', StandardMessageCodec());

final notepadConnector = NotepadConnector._();

class NotepadConnector {
  NotepadConnector._() {
    _message.setMessageHandler(_handleMessage);
  }

  void startScan() {
    _method
        .invokeMethod('startScan')
        .then((_) => print('startScan invokeMethod success'));
  }

  void stopScan() {
    _method
        .invokeMethod('stopScan')
        .then((_) => print('stopScan invokeMethod success'));
  }

  final Stream<NotepadScanResult> scanResultStream = _event_scanResult
      .receiveBroadcastStream({'name': 'scanResult'})
      .map((item) => NotepadScanResult.fromMap(item))
      .where(support);

  void connect(NotepadScanResult scanResult) {
    _method.invokeMethod('connect', {
      'deviceId': scanResult.deviceId,
    }).then((_) => print('connect invokeMethod success'));
  }

  void disconnect() {
    _method.invokeMethod('disconnect')
        .then((_) => print('disconnect invokeMethod success'));
  }

  Future<dynamic> _handleMessage(dynamic message) async {
    print('handleMessage $message');
    var connectionState = message['ConnectionState'];
    switch (connectionState) {
      case 'Connected':
        print('ConnectionState Connected');
        break;
      case 'Disconnected':
      default:
        print('ConnectionState Disconnected');
        break;
    }
  }
}