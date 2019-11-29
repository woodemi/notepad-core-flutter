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
  int percent;
  bool charging;

  BatteryInfo.fromMap(map)
      : this.percent = map['percent'],
        this.charging = map['charging'];
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
