import 'package:flutter/services.dart';

const method = const MethodChannel('notepad_core/method');
const event_scanResult = const EventChannel('notepad_core/event.scanResult');
const message = BasicMessageChannel('notepad_core/message', StandardMessageCodec());