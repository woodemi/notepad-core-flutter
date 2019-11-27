import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart' as NotepadCore;

class NotepadDetailPage extends StatefulWidget {
  final NotepadCore.NotepadScanResult scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

class _NotepadDetailPageState extends State<NotepadDetailPage> {
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
                  NotepadCore.connect(widget.scanResult);
                },
              ),
              RaisedButton(
                child: Text('disconnect'),
                onPressed: () {
                  NotepadCore.disconnect();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
