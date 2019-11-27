import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart' as NotepadCore;

class NotepadListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NotepadListPageState();
}

class _NotepadListPageState extends State<NotepadListPage> {
  StreamSubscription<NotepadCore.NotepadScanResult> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = NotepadCore.scanResultStream.listen((result) {
      if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
        setState(() => _scanResults.add(result));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NotepadListPage'),
      ),
      body: Column(
        children: <Widget>[
          buildButtons(),
          Divider(color: Colors.blue,),
          buildListView(),
        ],
      ),
    );
  }

  Widget buildButtons() {
    return Row(
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
    );
  }

  var _scanResults = List<NotepadCore.NotepadScanResult>();

  Widget buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) =>
            ListTile(
              title: Text(
                  '${_scanResults[index].name}(${_scanResults[index].rssi})'),
              subtitle: Text(_scanResults[index].deviceId),
            ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _scanResults.length,
      ),
    );
  }
}
