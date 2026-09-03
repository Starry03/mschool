import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveFileImpl({
  required Uint8List bytes,
  required String fileName,
  required String dialogTitle,
  String? mimeType,
}) async {
  final String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    bytes: bytes,
  );

  if (outputFile != null) {
    final file = File(outputFile);
    await file.writeAsBytes(bytes);
  }
}

