import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:notepad_core/Common.dart';
import 'package:notepad_core/Notepad.dart';
import 'package:notepad_core/NotepadClient.dart';
import 'package:notepad_core/native/BleType.dart';
import 'package:notepad_core/woodemi/FileRecord.dart';
import 'package:quiver/iterables.dart' show partition;
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
const CHAR__FILE_INPUT = '57444D05-$SUFFIX';

const WOODEMI_PREFIX = [0x57, 0x44, 0x4d]; // 'WDM'

final defaultAuthToken = Uint8List.fromList([0x00, 0x00, 0x00, 0x01]);

const MTU_WUART = 247;
const A1_WIDTH = 14800;
const A1_HEIGHT = 21000;

const SAMPLE_INTERVAL_MS = 5;

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
  Tuple2<String, String> get fileInputCharacteristic => const Tuple2(SERV__FILE_INPUT, CHAR__FILE_INPUT);

  @override
  List<Tuple2<String, String>> get inputIndicationCharacteristics => [
    commandResponseCharacteristic,
    fileInputControlResponseCharacteristic,
  ];

  @override
  List<Tuple2<String, String>> get inputNotificationCharacteristics => [
    syncInputCharacteristic,
    fileInputCharacteristic,
  ];

  @override
  Future<void> completeConnection(void awaitConfirm(bool)) async {
    var accessResult = await _checkAccess(authToken ?? defaultAuthToken, 10, awaitConfirm);
    switch(accessResult) {
      case AccessResult.Denied:
        throw AccessException.Denied;
      case AccessResult.Unconfirmed:
        throw AccessException.Unconfirmed;
      default:
        break;
    }

    await super.completeConnection(awaitConfirm);
    await notepadType.configMtu(MTU_WUART);
    _configMessageInput();
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

  //#region authorization
  setAuthToken(Uint8List authToken) {
    var newAuthToken = authToken ?? defaultAuthToken;
    assert(newAuthToken.length == 4, 'authToken should be 4 in length !');
    super.setAuthToken(newAuthToken);
  }

  Future<void> claimAuth() => _sendAuthRequest(authToken, true);

  Future<void> disclaimAuth() => _sendAuthRequest(authToken, false);

  Future<void> _sendAuthRequest(Uint8List authToken, bool claim) =>
      notepadType.executeCommand(WoodemiCommand(
        request: Uint8List.fromList(
          [0x04, claim ? 0x00 : 0x01] + authToken,
        ),
      ));

  //#endregion

  //#region Device Info
  @override
  Future<String> getDeviceName() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x04]),
      intercept: (value) => value.first == 0x0F,
      handle: (value) => utf8.decode(
        value.sublist(1),
      ),
    );
    return await notepadType.executeCommand(command);
  }

  @override
  Future<void> setDeviceName(String name) async {
    final list = utf8.encode(name);
    final data = list.length >= 15
        ? list.sublist(0, 15)
        : list + List.filled(15 - list.length, 0x00);
    return await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList([0x0B] + data),
      ),
    );
  }

  @override
  Future<BatteryInfo> getBatteryInfo() async {
    var percent = await notepadType.fetchProperty(Tuple2(SERV__BATTERY, CHAR__BATTERY_LEVEL), (value) {
      return value.buffer.asByteData().getUint8(0);
    });
    var charging = await notepadType.executeCommand(WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x03]),
      intercept: (value) => value[0] == 0x06 && value[1] == 0x01,
      handle: (value) => value[2] == 0x01
    ));
    return BatteryInfo(percent, charging);
  }

  @override
  Future<int> getDeviceDate() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x01]),
      intercept: (value) => value.first == 0x0C,
      handle: (value) => value.sublist(2).first,
    );
    return await notepadType.executeCommand(command);
  }

  @override
  Future<void> setDeviceDate(int second) async {
    final data = Uint32List.fromList([second]).buffer.asUint8List();
    await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList(
          [0x0A] + data.toList(),
        ),
      ),
    );
  }

  @override
  Future<void> setAutoLockTime(int minute) async {
    var byteData = ByteData(4);
    final second = Duration(minutes: minute).inSeconds;
    byteData.setUint32(0, second, Endian.little);
    await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList(
          [0x11, 0x01] + byteData.buffer.asUint8List(),
        ),
      ),
    );
  }

  @override
  Future<int> getAutoLockTime() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x05]),
      intercept: (value) => value.first == 0x10,
      handle: (value) {
        final byteData = value.buffer.asByteData();
        final seconds = byteData.getUint32(2, Endian.little);
        return Duration(seconds: seconds).inMinutes;
      },
    );
    return await notepadType.executeCommand(command);
  }
  //#endregion

  //#region SyncInput
  @override
  Future<void> setMode(NotepadMode notepadMode) async {
    var mode = notepadMode == NotepadMode.Sync ? 0x00 : 0x01;
    var bleConnectionPriority = notepadMode == NotepadMode.Sync ? BleConnectionPriority.high : BleConnectionPriority.balanced;
    notepadType.configConnectionPriority(bleConnectionPriority);
    await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList([0x05, mode]),
      ),
    );
  }

  @override
  List<NotePenPointer> parseSyncData(Uint8List value) {
    return parseSyncPointer(value).where((pointer) {
      return 0 <= pointer.x && pointer.x <= A1_WIDTH
          && 0<= pointer.y && pointer.y <= A1_HEIGHT;
    }).toList();
  }

  void _configMessageInput() {
    notepadType.receiveValue(commandResponseCharacteristic)
        .where((value) => value.first == 0x06)
        .map((value) {
          print('onMessageInputReceive ${hex.encode(value)}');
          return value;
        })
        .listen(_handleMessageInput);
  }

  void _handleMessageInput(Uint8List value) {
    var data = value.sublist(1);
    switch (data.first) {
      case 0x00:
        callback.handleEvent(KeyEvent(KeyEventType.KeyUp, KeyEventCode.Main));
        break;
    }
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

  /// Memo is kind of LargeData, transferred in data structure [ImageTransmission]
  /// +------------------------------------------------------------+
  /// |                          LargeData                         |
  /// +------------------------+----------+------------------------+
  /// | [ImageTransmission]    |   ...    |  [ImageTransmission]   |
  /// +------------------------+----------+------------------------+
  @override
  Future<MemoData> importMemo(void progress(int)) async {
    var info = await getLargeDataInfo();
    if (info.sizeInByte <= ImageTransmission.EMPTY_LENGTH) throw Exception('No memo');

    // TODO LargeData with multiple [ImageTransmission]
    var imageTransmission = await _requestTransmission(info.sizeInByte, progress);
    return MemoData(info, _parseMemo(imageTransmission.imageData, info.createdAt));
  }

  List<NotePenPointer> _parseMemo(Uint8List bytes, int createdAt) {
    var byteParts = partition(bytes, 6);
    var start = createdAt;
    var pointers = List<NotePenPointer>();
    for (var byteList in byteParts) {
      var byteData = Uint8List.fromList(byteList).buffer.asByteData();
      if (byteList[4] == 0xFF && byteList[5] == 0xFF) {
        start = byteData.getUint32(0, Endian.little);
      } else {
        pointers.add(NotePenPointer(
          byteData.getUint16(0, Endian.little),
          byteData.getUint16(0, Endian.little),
          start,
          byteData.getUint16(0, Endian.little),
        ));
        start += SAMPLE_INTERVAL_MS;
      }
    }
    return pointers;
  }

  /// +---------------------------------+
  /// |       [ImageTransmission]       |
  /// +----------+-----------+----------+
  /// |  block   |    ...    |   block  |
  /// +----------+-----------+----------+
  Future<ImageTransmission> _requestTransmission(int totalSize, void progress(int)) async {
    var data = Uint8List.fromList([]);
    while (data.length < totalSize) {
      var currentPos = data.length;
      var blockOffset = 0;
      Map<int, Uint8List> blockChunkMap = await _requestForNextBlock(currentPos, totalSize).fold(Map<int, Uint8List>(), (acc, value) {
        blockOffset += value.item2.length;
        if (progress != null) progress((currentPos + blockOffset) * 100 ~/ totalSize);
        acc[value.item1] = value.item2;
        return acc;
      });
      var sortedKeys = blockChunkMap.keys.toList()..sort();
      var block = sortedKeys.map((k) => blockChunkMap[k]).reduce((acc, bytes) => Uint8List.fromList(acc + bytes));
      print('receiveBlock size(${block.length})');
      data = Uint8List.fromList(data + block);
    }
    return ImageTransmission.forInput(data);
  }

  /// Request in file input control pipe
  /// +------------+--------------------------------------------------------------------------------------------+
  /// | requestTag |                                     requestData                                            |
  /// +------------+----------+-------------+------------+---------------+-----------------+--------------------+
  /// |            |  imageId |  currentPos |  BlockSize |  maxChunkSize |  transferMethod |  l2capChannelOrPsm |
  /// |            |          |             |            |               |                 |                    |
  /// | 1 byte     |  2 bytes |  4 bytes    |  4 bytes   |  2bytes       |  1 byte         |  2 bytes           |
  /// +------------+----------+-------------+------------+---------------+-----------------+--------------------+
  ///
  /// [maxChunkSize] not larger than (0xFFFF + 1)
  ///
  /// Response in file input data pipe
  /// +--------------------------------+
  /// |             block              |
  /// +----------+----------+----------+
  /// | chunk    |   ...    |  chunk   |
  /// +----------+----------+----------+
  Stream<Tuple2<int, Uint8List>> _requestForNextBlock(int currentPos, int totalSize) {
    var maxChunkSize = notepadType.mtu - 1 /*responseTag*/ - 1 /*chunkSeqId*/;
    var maxBlockSize = maxChunkSize * (0xFF + 1); // chunkSeqId(1 byte) -> maxChunkPerBlock
    var blockSize = min(totalSize - currentPos, maxBlockSize);
    var transferMethod = 0;
    var l2capChannelOrPsm = 0x0004;

    print('requestForNextBlock currentPos $currentPos, totalSize $totalSize, blockSize, $blockSize, maxChunkSize $maxChunkSize');

    var imageId = fileInfo.item1;
    var byteData = ByteData(imageId.length + 4 + 4 + 2 + 1 + 2);
    var position = 0;
    for (var b in imageId)
      byteData.setInt8(position++, b);
    byteData.setUint32(position, currentPos, Endian.little);
    byteData.setUint32(position += 4, blockSize, Endian.little);
    byteData.setUint16(position += 4, maxChunkSize, Endian.little);
    byteData.setUint8(position += 2, transferMethod);
    byteData.setUint16(position += 1, l2capChannelOrPsm, Endian.little);
    var request = Uint8List.fromList([0x04] + byteData.buffer.asUint8List());

    var chunkCountCeil = (blockSize / maxChunkSize).ceil();
    var indexedChunkStream = _receiveChunks(chunkCountCeil);

    notepadType.sendRequestAsync('FileInputControl', fileInputControlRequestCharacteristic, request);

    return indexedChunkStream;
  }

  /// +-------------+--------------------------+
  /// | responseTag |       responseData       |
  /// +-------------+-------------+------------+
  /// |             |  chunkSeqId |  chunkData |
  /// |             |             |            |
  /// | 1 byte      |  1 byte     |  ...       |
  /// +-------------+-------------+------------+
  Stream<Tuple2<int, Uint8List>> _receiveChunks(int count) => notepadType.receiveFileInput()
    .where((value) => value.first == 0x05)
    // TODO Take with timeout
    .take(count)
    .map((value) => Tuple2(value[1], value.sublist(2)));

  @override
  Future<void> deleteMemo() async {
    // TODO Deal with 0x01 as notification instead of response
    await notepadType.sendRequestAsync('FileInputControl', fileInputControlRequestCharacteristic, Uint8List.fromList([0x06, 0x00, 0x00, 0x00]));
  }
  //#endregion

  //#region Version
  @override
  Future<VersionInfo> getVersionInfo() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x00]),
      intercept: (value) => value.first == 0x09,
      handle: (value) {
        final data = value.sublist(1);
        final hardware = Version(data[1], data[2]);
        final software = Version(data[3], data[4], data[5]);
        return VersionInfo(hardware: hardware, software: software);
      },
    );
    return await notepadType.executeCommand(command);
  }

  @override
  Future<void> upgrade(String filePath, Version version, void progress(int)) async {
    final fileData = await parseUpgradeFile(filePath);
    final imageId = hex.decode('0100');
    final imageVersion = Uint8List.fromList(version.bytes.reversed.toList() + hex.decode('4111111101'));
    final imageData = ImageTransmission.forOutput(imageId, imageVersion, fileData).bytes;
    return null;
  }
  //#endregion
}
