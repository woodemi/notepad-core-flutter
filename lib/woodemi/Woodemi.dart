import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:notepad_core/src/NotepadCommand.dart';

class WoodemiCommand<T> extends NotepadCommand<T> {
  WoodemiCommand({
    @required Uint8List request,
    @required Predicate intercept,
    @required Handle<T> handle,
  }) : super(
    request: request,
    intercept: intercept,
    handle: handle,
  );
}