import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

class NotepadMethod {
  String name;
  VoidCallback call;

  NotepadMethod({@required this.name, @required this.call});
}

class NotepadDetailPage extends StatefulWidget {
  final NotepadScanResult scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

class _NotepadDetailPageState extends State<NotepadDetailPage> implements NotepadClientCallback {
  var _notepadMethods = List<NotepadMethod>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    notepadConnector.setConnectionChangeHandler(handleConnectionChange);

    initData();
  }

  @override
  void dispose() {
    super.dispose();
    notepadConnector.setConnectionChangeHandler(null);
  }

  initData() => {
        _notepadMethods.addAll([
          NotepadMethod(
            name: 'connect',
            call: () => notepadConnector.connect(widget.scanResult),
          ),
          NotepadMethod(
            name: 'disconnect',
            call: () => notepadConnector.disconnect(),
          ),
          NotepadMethod(
            name: 'getDeviceName',
            call: () async =>
                _toast('DeviceName: ${await _notepadClient.getDeviceName()}'),
          ),
          NotepadMethod(
            name: 'setDeviceName',
            call: () async => {
              await _notepadClient.setDeviceName('123'),
              _toast('New DeviceName: ${await _notepadClient.getDeviceName()}'),
            },
          ),
          NotepadMethod(
            name: 'getVersionInfo',
            call: () async {
              VersionInfo version = await _notepadClient.getVersionInfo();
              _toast(
                  'version.hardware = ${version.hardware.major}  version.software = ${version.hardware.minor} version.software = ${version.software.major} version.software = ${version.software.minor} version.software = ${version.software.patch}');
            },
          ),
          NotepadMethod(
            name: 'getBatteryInfo',
            call: () async {
              BatteryInfo battery = await _notepadClient.getBatteryInfo();
              _toast(
                  'battery.percent = ${battery.percent}  battery.charging = ${battery.charging}');
            },
          ),
          NotepadMethod(
            name: 'getDeviceDate',
            call: () async =>
                _toast('date = ${await _notepadClient.getDeviceDate()}'),
          ),
          NotepadMethod(
            name: 'setDeviceDate',
            call: () async => {
              await _notepadClient.setDeviceDate(0),
              _toast(
                  'new DeivceDate = ${await _notepadClient.getDeviceDate()}'),
            },
          ),
          NotepadMethod(
            name: 'getAutoLockTime',
            call: () async => _toast(
                'AutoLockTime = ${await _notepadClient.getAutoLockTime()}'),
          ),
          NotepadMethod(
            name: 'setAutoLockTime',
            call: () async => {
              await _notepadClient.setAutoLockTime(10),
              _toast(
                  'new AutoLockTime = ${await _notepadClient.getAutoLockTime()}')
            },
          ),
          NotepadMethod(
            name: 'setMode',
            call: () => _notepadClient.setMode(NotepadMode.Sync),
          ),
        ]),
        setState(() => print),
      };

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
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('NotepadDetailPage'),
      ),
      body: ListView.separated(
        itemCount: _notepadMethods.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_notepadMethods[index].name),
          onTap: _notepadMethods[index].call,
        ),
        separatorBuilder: (context, index) => Divider(),
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
