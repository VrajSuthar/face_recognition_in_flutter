import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Runs before every test file: sqflite's plugin needs a phone, so tests use
/// the desktop (FFI) SQLite build instead.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
