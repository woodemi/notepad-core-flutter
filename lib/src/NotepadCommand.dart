import 'dart:typed_data';

import 'package:flutter/foundation.dart';

typedef Predicate = bool Function(Uint8List data);

typedef Handle<T> = T Function(Uint8List data);

class NotepadCommand<T> {
  final Uint8List request;
  final Predicate intercept;
  final Handle<T> handle;

  NotepadCommand({
    @required this.request,
    @required this.intercept,
    @required this.handle,
  })
      : assert(request != null),
        assert(intercept != null),
        assert(handle != null);
}