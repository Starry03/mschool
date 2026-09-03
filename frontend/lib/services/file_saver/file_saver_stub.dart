import 'dart:typed_data';

Future<void> saveFileImpl({
  required Uint8List bytes,
  required String fileName,
  required String dialogTitle,
  String? mimeType,
}) async {
  throw UnsupportedError('Piattaforma non supportata per il salvataggio file.');
}

