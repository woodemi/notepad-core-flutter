import 'dart:typed_data';

class NotepadScanResult {
  String name;
  String deviceId;
  Uint8List manufacturerData;
  int rssi;

  NotepadScanResult.fromMap(map)
      : name = map['name'],
        deviceId = map['deviceId'],
        manufacturerData = map['manufacturerData'],
        rssi = map['rssi'];

  Map toMap() => {
        'name': name,
        'deviceId': deviceId,
        'manufacturerData': manufacturerData,
        'rssi': rssi,
      };
}

enum NotepadMode { Sync, Common }

class BatteryInfo {
  final int percent;
  final bool charging;

  BatteryInfo(this.percent, this.charging);
}

class VersionInfo {
  Version hardware;
  Version software;

  VersionInfo({this.hardware, this.software});
}

class Version {
  final int major;
  final int minor;
  final int patch;

  Version(this.major, [this.minor, this.patch]);

  Uint8List get bytes => Uint8List.fromList([
        major,
        if (minor != null) minor,
        if (patch != null) patch,
      ]);
}

class NotePenPointer {
  int x;
  int y;
  int t;
  int p;

  NotePenPointer(this.x, this.y, this.t, this.p);

  NotePenPointer.fromMap(map)
      : this.x = map['x'],
        this.y = map['y'],
        this.t = map['t'],
        this.p = map['p'];

  Map toMap() => {
    'x': x,
    'y': y,
    't': t,
    'p': p,
  };
}

class MemoSummary {
  final int memoCount;
  final int totalCapacity;
  final int freeCapacity;
  final int usedCapacity;

  MemoSummary(this.memoCount, this.totalCapacity, this.freeCapacity, this.usedCapacity);

  @override
  String toString() => '$memoCount, $totalCapacity, $freeCapacity, $usedCapacity';
}

class MemoInfo {
  final int sizeInByte;
  // milliseconds
  final int createdAt;
  final int partIndex;
  // Rest part count in current transportation
  final int restCount;

  MemoInfo(this.sizeInByte, this.createdAt, this.partIndex, this.restCount);

  @override
  String toString() => '$sizeInByte, $createdAt, $partIndex, $restCount';
}

class MemoData {
  final MemoInfo memoInfo;
  final List<NotePenPointer> pointers;

  MemoData(this.memoInfo, this.pointers);

  @override
  String toString() => '$memoInfo, pointers[${pointers.length}]';
}

class NotepadEvent {

}

class KeyEvent implements NotepadEvent {
  final KeyEventType type;
  final KeyEventCode code;

  KeyEvent(this.type, this.code);
}

enum KeyEventType {
  KeyDown, KeyUp
}

enum KeyEventCode {
  Main
}