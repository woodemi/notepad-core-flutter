import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import 'Notepad.dart';
import 'NotepadType.dart';

abstract class NotepadClientCallback {
  void handlePointer(List<NotePenPointer> list);
}

abstract class NotepadClient {
  Tuple2<String, String> get commandRequestCharacteristic;

  Tuple2<String, String> get commandResponseCharacteristic;

  Tuple2<String, String> get syncInputCharacteristic;

  List<Tuple2<String, String>> get inputIndicationCharacteristics;

  List<Tuple2<String, String>> get inputNotificationCharacteristics;

  NotepadType notepadType;

  Future<void> completeConnection(void awaitConfirm(bool)) {
    // TODO Cancel
    notepadType.receiveSyncInput().listen((value) {
      callback?.handlePointer(parseSyncData(value));
    });
  }

  Future<String> getDeviceName();

  Future<void> setDeviceName(String name);

  Future<BatteryInfo> getBatteryInfo();

  Future<int> getDeviceDate();

  Future<void> setDeviceDate(int date);

  Future<int> getAutoLockTime(); // minute

  Future<void> setAutoLockTime(int time); // minute

  Future<VersionInfo> getVersionInfo();

  NotepadClientCallback callback;

  //#region SyncInput
  Future<void> setMode(NotepadMode notepadMode);

  List<NotePenPointer> parseSyncData(Uint8List value);
  //#endregion
}
