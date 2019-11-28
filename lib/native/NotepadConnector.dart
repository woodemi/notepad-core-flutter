import '../Common.dart';
import '../Notepad.dart';
import '../NotepadClient.dart';
import '../NotepadType.dart';
import 'notepad_core_native.dart';

typedef ConnectionChangeHandler = void Function(NotepadClient client, String state);

final notepadConnector = NotepadConnector._();

class NotepadConnector {
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

  void connect(NotepadScanResult scanResult) {
    _notepadClient = create(scanResult);
    _notepadType = NotepadType(_notepadClient);
    method.invokeMethod('connect', {
      'deviceId': scanResult.deviceId,
    }).then((_) => print('connect invokeMethod success'));
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
    print('handleMessage $message');
    if (message['ConnectionState'] != null) {
      if (message['ConnectionState'] == 'Connected')
        method.invokeMethod('discoverServices').then((_) =>
            print('discoverServices invokeMethod success'));
      else
        _connectionChangeHandler(_notepadClient, message['ConnectionState']);
    } else if (message['ServiceState'] != null) {
      if (message['ServiceState'] == 'Discovered')
        _notepadType.configCharacteristics();
    }
  }
}