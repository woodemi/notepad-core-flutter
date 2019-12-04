import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tf_toast/Toast.dart';
import 'package:tuple/tuple.dart';

class NotepadDetailPage extends StatefulWidget {
  final NotepadScanResult scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

class _NotepadDetailPageState extends State<NotepadDetailPage>
    implements NotepadClientCallback {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    notepadConnector.setConnectionChangeHandler(handleConnectionChange);
  }

  @override
  void dispose() {
    super.dispose();
    notepadConnector.setConnectionChangeHandler(null);
  }

  NotepadClient _notepadClient;

  void handleConnectionChange(NotepadClient client, String state) {
    print('handleConnectionChange $client $state');
    if (state == 'Connected') {
      _notepadClient = client;
      _notepadClient.callback = this;
    } else {
      _notepadClient?.callback = null;
      _notepadClient = null;
    }
  }

  @override
  void handlePointer(List<NotePenPointer> list) {
    print('handlePointer ${list.length}');
  }

  @override
  void handleEvent(NotepadEvent notepadEvent) {
    print('handleEvent $notepadEvent');
    Toast.show(context, title: notepadEvent.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('NotepadDetailPage'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('connect'),
                  onPressed: () {
                    notepadConnector.connect(widget.scanResult);
                  },
                ),
                RaisedButton(
                  child: Text('disconnect'),
                  onPressed: () {
                    notepadConnector.disconnect();
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('claimAuth'),
                  onPressed: () async {
                    if (_notepadClient != null) {
                      await _notepadClient.claimAuth();
                      Toast.show(context, title: 'claimAuth success');
                    } else {
                      Toast.show(context, title: '_notepadClient = null');
                    }
                  },
                ),
                RaisedButton(
                  child: Text('disclaimAuth'),
                  onPressed: () async {
                    if (_notepadClient != null) {
                      await _notepadClient.disclaimAuth();
                      Toast.show(context, title: 'disclaimAuth success');
                    } else {
                      Toast.show(context, title: '_notepadClient = null');
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('getDeviceName'),
                  onPressed: () async {
                    _toast('DeviceName: ${await _notepadClient.getDeviceName()}');
                  },
                ),
                RaisedButton(
                  child: Text('setDeviceName'),
                  onPressed: () async => {
                    await _notepadClient.setDeviceName('abc'),
                    _toast(
                        'New DeviceName: ${await _notepadClient.getDeviceName()}'),
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('getDeviceDate'),
                  onPressed: () async {
                    _toast('date = ${await _notepadClient.getDeviceDate()}');
                  },
                ),
                RaisedButton(
                  child: Text('setDeviceDate'),
                  onPressed: () async => {
                    await _notepadClient.setDeviceDate(0), // second
                    _toast(
                        'new DeivceDate = ${await _notepadClient.getDeviceDate()}'),
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('getAutoLockTime'),
                  onPressed: () async => _toast(
                      'AutoLockTime = ${await _notepadClient.getAutoLockTime()}'),
                ),
                RaisedButton(
                  child: Text('setAutoLockTime'),
                  onPressed: () async => {
                    await _notepadClient.setAutoLockTime(10),
                    _toast(
                        'new AutoLockTime = ${await _notepadClient.getAutoLockTime()}')
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('getDeviceSize'),
                  onPressed: () async {
                    Tuple2<int, int> size = _notepadClient.getDeviceSize();
                    _toast(
                        'device size = $size');
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('getBatteryInfo'),
                  onPressed: () async {
                    BatteryInfo battery = await _notepadClient.getBatteryInfo();
                    _toast(
                        'battery.percent = ${battery.percent}  battery.charging = ${battery.charging}');
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('setMode'),
                  onPressed: () {
                    _notepadClient.setMode(NotepadMode.Sync);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('getMemoSummary'),
                  onPressed: () async {
                    var memoSummary = await _notepadClient.getMemoSummary();
                    print('getMemoSummary $memoSummary');
                  },
                ),
                RaisedButton(
                  child: Text('getMemoInfo'),
                  onPressed: () async {
                    var memoInfo = await _notepadClient.getMemoInfo();
                    print('getMemoInfo $memoInfo');
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('importMemo'),
                  onPressed: () async {
                    var memoData = await _notepadClient
                        .importMemo((progress) => print('progress $progress'));
                    print('importMemo $memoData');
                  },
                ),
                RaisedButton(
                  child: Text('deleteMemo'),
                  onPressed: () {
                    _notepadClient.deleteMemo();
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('importMemo all'),
                  onPressed: () async {
                    var memoSummary = await _notepadClient.getMemoSummary();
                    for (var i = 0; i < memoSummary.memoCount; i++) {
                      await _notepadClient.importMemo((progress) => print('progress $progress'));
                      await _notepadClient.deleteMemo();
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('getVersionInfo'),
                  onPressed: () async {
                    VersionInfo version = await _notepadClient.getVersionInfo();
                    _toast(
                        'version.hardware = ${version.hardware.major}  version.software = ${version.hardware.minor} version.software = ${version.software.major} version.software = ${version.software.minor} version.software = ${version.software.patch}');
                  },
                ),
                RaisedButton(
                  child: Text('upgrade'),
                  onPressed: () async {
                    var appDocDir = await getApplicationDocumentsDirectory();
                    _notepadClient.upgrade('${appDocDir.path}/1_1_4.srec', Version(0xFF, 0xFF, 0xFF), (progress) {
                      print('upgrade progress $progress');
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _toast(String msg) => _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: Duration(seconds: 2),
        ),
      );
}
