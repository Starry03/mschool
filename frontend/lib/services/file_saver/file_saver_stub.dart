import 'dart:typed_data';

Future<void> saveFileImpl({
  required Uint8List bytes,
  required String fileName,
  required String dialogTitle,
  String? mimeType,
}) async {
  throw UnsupportedError('Platform not supported for file saving.');
}

