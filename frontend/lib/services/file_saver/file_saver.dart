import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

class FileSaver {
  static Future<void> saveFile({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    String? mimeType,
  }) {
    return saveFileImpl(
      bytes: bytes,
      fileName: fileName,
      dialogTitle: dialogTitle,
      mimeType: mimeType,
    );
  }
}

