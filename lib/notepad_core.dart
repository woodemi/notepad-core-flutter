import 'package:flutter/services.dart';

const _method = const MethodChannel('notepad_core/method');

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
