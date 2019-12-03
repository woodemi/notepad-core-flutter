import 'dart:io';

// FIXME https://stackoverflow.com/a/57086750
Future<String> findFilePath(String path) async => await File(path).exists() ? path : '../$path';

Future<String> findDirectoryPath(String path) async => await Directory(path).exists() ? path : '../$path';
