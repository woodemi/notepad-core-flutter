import 'dart:typed_data';

import 'package:notepad_core/Common.dart';
import 'package:notepad_core/Notepad.dart';
import 'package:notepad_core/NotepadClient.dart';
import 'package:tuple/tuple.dart';

import 'Woodemi.dart';

const SUFFIX = 'BA5E-F4EE-5CA1-EB1E5E4B1CE0';

const SERV__COMMAND = '57444D01-$SUFFIX';
const CHAR__COMMAND_REQUEST = '57444E02-$SUFFIX';
const CHAR__COMMAND_RESPONSE = CHAR__COMMAND_REQUEST;

const SERV__SYNC = '57444D06-$SUFFIX';
const CHAR__SYNC_INPUT = '57444D07-$SUFFIX';

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
  List<Tuple2<String, String>> get inputIndicationCharacteristics => [
    commandResponseCharacteristic,
  ];

  @override
  List<Tuple2<String, String>> get inputNotificationCharacteristics => [
    syncInputCharacteristic
  ];

  @override
  Future<void> completeConnection(void awaitConfirm(bool)) async {
    await super.completeConnection(awaitConfirm);
    var accessResult = await _checkAccess(authToken ?? defaultAuthToken, 10, awaitConfirm);
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

  //#region authorization
  setAuthToken([Uint8List authToken]) {
    var newAuthToken = authToken != null
        ? authToken
        : Uint8List.fromList([0x00, 0x00, 0x00, 0x01]);
    assert(newAuthToken.length == 4, 'authToken should be 4 in length !');
    this.authToken = authToken;
  }

  Future<void> claimAuth() async {
    await sendAuthRequest(authToken, true);
  }

  Future<void> disclaimAuth() async {
    if (authToken != null) sendAuthRequest(authToken, false);
  }

  Future<void> sendAuthRequest(Uint8List authToken, [bool claim = false]) async {
    var req = Uint8List.fromList([0x04, claim ? 0x00 : 0x01] + authToken.toList()) ;
    await notepadType.executeCommand(WoodemiCommand(request: req));
  }
  //#endregion
}
