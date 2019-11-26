import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart' as NotepadCore;

class NotepadListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NotepadListPage'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('startScan'),
                onPressed: () => NotepadCore.startScan(),
              ),
              RaisedButton(
                child: Text('stopScan'),
                onPressed: () => NotepadCore.stopScan(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
