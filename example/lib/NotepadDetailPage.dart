import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

class NotepadDetailPage extends StatefulWidget {
  final NotepadScanResult scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

class _NotepadDetailPageState extends State<NotepadDetailPage> {
  @override
  void initState() {
    super.initState();
    notepadConnector.setConnectionChangeHandler(_connectionChangeHandler);
  }

  @override
  void dispose() {
    super.dispose();
    notepadConnector.setConnectionChangeHandler(null);
  }

  final ConnectionChangeHandler _connectionChangeHandler = (client, state) {
    print('ConnectionChangeHandler $client $state');
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NotepadDetailPage'),
      ),
      body: Column(
        children: <Widget>[
          Row(
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
        ],
      ),
    );
  }
}
