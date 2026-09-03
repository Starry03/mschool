import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> saveFileImpl({
  required Uint8List bytes,
  required String fileName,
  required String dialogTitle,
  String? mimeType,
}) async {
  final jsBytes = bytes.toJS;
  final parts = [jsBytes].toJS;
  final options = web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream');
  final blob = web.Blob(parts, options);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

