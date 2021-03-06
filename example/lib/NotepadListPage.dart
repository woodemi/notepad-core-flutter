import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

import 'NotepadDetailPage.dart';

class NotepadListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NotepadListPageState();
}

class _NotepadListPageState extends State<NotepadListPage> {
  StreamSubscription<NotepadScanResult> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = notepadConnector.scanResultStream.listen((result) {
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
          onPressed: () => notepadConnector.startScan(),
        ),
        RaisedButton(
          child: Text('stopScan'),
          onPressed: () => notepadConnector.stopScan(),
        ),
      ],
    );
  }

  var _scanResults = List<NotepadScanResult>();

  Widget buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) =>
            ListTile(
              title: Text(
                  '${_scanResults[index].name}(${_scanResults[index].rssi})'),
              subtitle: Text(_scanResults[index].deviceId),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => NotepadDetailPage(_scanResults[index]),
                ));
              },
            ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _scanResults.length,
      ),
    );
  }
}
