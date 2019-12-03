import 'dart:typed_data';
import 'dart:ui';

import 'package:tuple/tuple.dart';

import 'Notepad.dart';
import 'NotepadType.dart';

const GSS_SUFFIX = "0000-1000-8000-00805F9B34FB";
const CODE__SERV_BATTERY = "180F";
const CODE__CHAR_BATTERY_LEVEL = "2A19";

const SERV__BATTERY = "0000$CODE__SERV_BATTERY-$GSS_SUFFIX";
const CHAR__BATTERY_LEVEL = "0000$CODE__CHAR_BATTERY_LEVEL-$GSS_SUFFIX";

abstract class NotepadClientCallback {
  void handlePointer(List<NotePenPointer> list);

  void handleEvent(NotepadEvent notepadEvent);
}

abstract class NotepadClient {
  Tuple2<String, String> get commandRequestCharacteristic;

  Tuple2<String, String> get commandResponseCharacteristic;

  Tuple2<String, String> get syncInputCharacteristic;

  Tuple2<String, String> get fileInputControlRequestCharacteristic;

  Tuple2<String, String> get fileInputControlResponseCharacteristic;

  Tuple2<String, String> get fileInputCharacteristic;

  Tuple2<String, String> get fileOutputControlRequestCharacteristic;

  Tuple2<String, String> get fileOutputControlResponseCharacteristic;

  Tuple2<String, String> get fileOutputCharacteristic;

  List<Tuple2<String, String>> get inputIndicationCharacteristics;

  List<Tuple2<String, String>> get inputNotificationCharacteristics;

  NotepadType notepadType;

  Future<void> completeConnection(void awaitConfirm(bool)) {
    // TODO Cancel
    notepadType.receiveSyncInput().listen((value) {
      callback?.handlePointer(parseSyncData(value));
    });
  }

  NotepadClientCallback callback;

  //#region authorization
  Uint8List _authToken;

  Uint8List get authToken => _authToken;

  void setAuthToken(Uint8List authToken) {
    _authToken = authToken;
  }

  Future<void> claimAuth();

  Future<void> disclaimAuth();
  //#endregion

  //#region device info
  Future<String> getDeviceName();

  Future<void> setDeviceName(String name);

  Future<BatteryInfo> getBatteryInfo();

  Future<int> getDeviceDate();

  Future<void> setDeviceDate(int date);

  Future<Size> getDeviceSize();

  Future<int> getAutoLockTime(); // minute

  Future<void> setAutoLockTime(int time); // minute
  //#endregion

  //#region SyncInput
  Future<void> setMode(NotepadMode notepadMode);

  List<NotePenPointer> parseSyncData(Uint8List value);
  //#endregion

  //#region ImportMemo
  Future<MemoSummary> getMemoSummary();

  Future<MemoInfo> getMemoInfo();

  Future<MemoData> importMemo(void progress(int));

  Future<void> deleteMemo();
  //#endregion

  //#region Version
  Future<VersionInfo> getVersionInfo();

  Future<void> upgrade(String filePath, Version version, void progress(int));
  //#endregion
}
