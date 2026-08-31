/// Local ranking backup/restore. The real implementation needs the native
/// sqlite library (dart:ffi), which does not exist on the web — the stub
/// reports the feature as unsupported there.
export 'backup_stub.dart' if (dart.library.ffi) 'backup_io.dart';
