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

  VersionInfo.fromMap(map)
      : this.hardware = Version.fromMap(map['hardware']),
        this.software = Version.fromMap(map['software']);
}

class Version {
  int major;
  int minor;
  int patch;

  Version(int major, [int minor, int patch])
      : this.major = major,
        this.minor = minor,
        this.patch = patch;

  Version.fromMap(map)
      : this.major = map['major'],
        this.minor = map['minor'],
        this.patch = map['patch'];

  Map toMap() => {
        'major': major,
        'minor': minor,
        'patch': patch,
      };

  String get description =>
      '$major' +
      (minor != null ? '.$minor' : '') +
      (patch != null ? '.$patch' : '');
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

abstract class NotepadEvent {

  factory NotepadEvent.KeyEvent(KeyEventType type, KeyEventCode code) {
    return KeyEvent(type, code);
  }

  factory NotepadEvent.BatteryAlertEvent() {
    return BatteryAlertEvent();
  }

  factory NotepadEvent.ChargingStatusEvent(ChargingStatusEventType type) {
    return ChargingStatusEvent(type);
  }

  factory NotepadEvent.StorageAlertEvent() {
    return StorageAlertEvent();
  }
}

class KeyEvent implements NotepadEvent {
  final KeyEventType type;
  final KeyEventCode code;

  KeyEvent(this.type, this.code);
}

enum KeyEventType { KeyUp }

enum KeyEventCode { Main }

class BatteryAlertEvent implements NotepadEvent {
  BatteryAlertEvent();
}

class ChargingStatusEvent implements NotepadEvent {
  final ChargingStatusEventType type;

  ChargingStatusEvent(this.type);
}

enum ChargingStatusEventType { PowerOn, PowerOff }

class StorageAlertEvent implements NotepadEvent {
  StorageAlertEvent();
}