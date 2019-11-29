import 'dart:typed_data';

import 'package:notepad_core/Common.dart';
import 'package:notepad_core/Notepad.dart';
import 'package:notepad_core/NotepadClient.dart';
import 'package:tuple/tuple.dart';

import 'ImageTransimission.dart';
import 'Woodemi.dart';

const SUFFIX = 'BA5E-F4EE-5CA1-EB1E5E4B1CE0';

const SERV__COMMAND = '57444D01-$SUFFIX';
const CHAR__COMMAND_REQUEST = '57444E02-$SUFFIX';
const CHAR__COMMAND_RESPONSE = CHAR__COMMAND_REQUEST;

const SERV__SYNC = '57444D06-$SUFFIX';
const CHAR__SYNC_INPUT = '57444D07-$SUFFIX';

const SERV__FILE_INPUT = '57444D03-$SUFFIX';
const CHAR__FILE_INPUT_CONTROL_REQUEST = '57444D04-$SUFFIX';
const CHAR__FILE_INPUT_CONTROL_RESPONSE = CHAR__FILE_INPUT_CONTROL_REQUEST;

const WOODEMI_PREFIX = [0x57, 0x44, 0x4d]; // 'WDM'

final defaultAuthToken = Uint8List.fromList([0x00, 0x00, 0x00, 0x01]);

const A1_WIDTH = 14800;
const A1_HEIGHT = 21000;


enum AccessResult {
  Denied,      // Device claimed by other user
  Confirmed,   // Access confirmed, indicating device not claimed by anyone
  Unconfirmed, // Access unconfirmed, as user doesn't confirm before timeout
  Approved     // Device claimed by this user
}

class WoodemiClient extends NotepadClient {
  @override
  Tuple2<String, String> get commandRequestCharacteristic => const Tuple2(SERV__COMMAND, CHAR__COMMAND_REQUEST);

  @override
  Tuple2<String, String> get commandResponseCharacteristic => const Tuple2(SERV__COMMAND, CHAR__COMMAND_RESPONSE);

  @override
  Tuple2<String, String> get syncInputCharacteristic => const Tuple2(SERV__SYNC, CHAR__SYNC_INPUT);

  @override
  Tuple2<String, String> get fileInputControlRequestCharacteristic => const Tuple2(SERV__FILE_INPUT, CHAR__FILE_INPUT_CONTROL_REQUEST);

  @override
  Tuple2<String, String> get fileInputControlResponseCharacteristic => const Tuple2(SERV__FILE_INPUT, CHAR__FILE_INPUT_CONTROL_RESPONSE);

  @override
  List<Tuple2<String, String>> get inputIndicationCharacteristics => [
    commandResponseCharacteristic,
    fileInputControlResponseCharacteristic,
  ];

  @override
  List<Tuple2<String, String>> get inputNotificationCharacteristics => [
    syncInputCharacteristic
  ];

  @override
  Future<void> completeConnection(void awaitConfirm(bool)) async {
    await super.completeConnection(awaitConfirm);
    var accessResult = await _checkAccess(defaultAuthToken, 10, awaitConfirm);
    switch(accessResult) {
      case AccessResult.Denied:
        throw AccessException.Denied;
      case AccessResult.Unconfirmed:
        throw AccessException.Unconfirmed;
      default:
        break;
    }
  }

  Future<AccessResult> _checkAccess(Uint8List authToken, int seconds, void awaitConfirm(bool)) async {
    var command = WoodemiCommand(
      request: Uint8List.fromList([0x01, seconds] + authToken),
      intercept: (data) => data.first == 0x02,
      handle: (data) => data[1],
    );
    var response = await notepadType.executeCommand(command);
    switch(response) {
      case 0x00:
        return AccessResult.Denied;
      case 0x01:
        awaitConfirm(true);
        var confirm = await notepadType.receiveResponseAsync('Confirm',
            commandResponseCharacteristic, (value) => value.first == 0x03);
        return confirm[1] == 0x00 ? AccessResult.Confirmed : AccessResult.Unconfirmed;
      case 0x02:
        return AccessResult.Approved;
      default:
        throw Exception('Unknown error');
    }
  }

  //#region SyncInput
  @override
  Future<void> setMode(NotepadMode notepadMode) async {
    var mode = notepadMode == NotepadMode.Sync ? 0x00 : 0x01;
    await notepadType.executeCommand(WoodemiCommand(
      request: Uint8List.fromList([0x05, mode]),
    ));
  }

  @override
  List<NotePenPointer> parseSyncData(Uint8List value) {
    return parseSyncPointer(value).where((pointer) {
      return 0 <= pointer.x && pointer.x <= A1_WIDTH
          && 0<= pointer.y && pointer.y <= A1_HEIGHT;
    }).toList();
  }
  //#endregion

  //#region ImportMemo
  @override
  Future<MemoSummary> getMemoSummary() {
    var handle = (Uint8List value) {
      var byteData = value.buffer.asByteData();
      var position = 1; // skip 1
      var totalCapacity = byteData.getUint32(position, Endian.little);
      var freeCapacity = byteData.getUint32(position += 4, Endian.little);
      var usedCapacity = byteData.getUint32(position += 4, Endian.little);
      var memoCount = byteData.getUint16(position += 4, Endian.little);
      return MemoSummary(memoCount, totalCapacity, freeCapacity, usedCapacity);
    };
    return notepadType.executeCommand(WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x02]),
      intercept: (value) => value.first == 0x0D,
      handle: handle,
    ));
  }

  @override
  Future<MemoInfo> getMemoInfo() async {
    var largeDataInfo = await getLargeDataInfo();
    return MemoInfo(
      largeDataInfo.sizeInByte - ImageTransmission.EMPTY_LENGTH,
      largeDataInfo.createdAt,
      largeDataInfo.partIndex,
      largeDataInfo.restCount,
    );
  }

  Future<MemoInfo> getLargeDataInfo() async {
    var data = fileInfo.item1 + fileInfo.item2;
    var handle = (Uint8List value) {
      var byteData = value.buffer.asByteData();
      var position = 1; // skip 1
      var partIndex = byteData.getUint8(position);
      var restCount = byteData.getUint8(position += 1);

      position += 1;
      var chars = value.sublist(position, position + fileInfo.item2.length);
      var seconds = int.parse(String.fromCharCodes(chars, 0, chars.length), radix: 16);
      var createdAt = Duration(seconds: seconds).inMilliseconds;
      
      var sizeInByte = byteData.getUint32(position += fileInfo.item2.length, Endian.little);
      return MemoInfo(sizeInByte, createdAt, partIndex, restCount);
    };

    return notepadType.executeFileInputControl(WoodemiCommand(
      request: Uint8List.fromList([0x02] + data),
      intercept: (value) => value.first == 0x03,
      handle: handle,
    ));
  }

  final fileInfo = Tuple2(
    Uint8List.fromList([0x00, 0x01]), // imageId
    Uint8List.fromList([ // imageVersion
      0x01, 0x00, 0x00, // Build Version
      0x41, // Stack Version
      0x11, 0x11, 0x11, // Hardware Id
      0x01 // Manufacturer Id
    ])
  );
  //#endregion
}
