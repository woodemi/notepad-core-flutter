import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

class NotepadDetailPage extends StatefulWidget {
  final NotepadScanResult scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

class _NotepadDetailPageState extends State<NotepadDetailPage> {
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
    } else {
      _notepadClient = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('NotepadDetailPage'),
      ),
      body: Column(
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
                child: Text('getDeviceName'),
                onPressed: () async {
                  _toast(await _notepadClient.getDeviceName());
                },
              ),
              RaisedButton(
                child: Text('setDeviceName'),
                onPressed: () async {
                  await _notepadClient.setDeviceName('setDeviceName');
                  _toast(await _notepadClient.getDeviceName());
                },
              ),
            ],
          ),
        ],
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
