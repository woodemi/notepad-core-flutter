import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

class NotepadDetailPage extends StatefulWidget {
  final NotepadScanResult scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

class _NotepadDetailPageState extends State<NotepadDetailPage> implements NotepadClientCallback {
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
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
    );
  }
}
