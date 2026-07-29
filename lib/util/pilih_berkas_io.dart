import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<({Uint8List bytes, String filename})?> pilihBerkasExcel() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls', 'csv'],
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    Uint8List? bytes = file.bytes;

    if (bytes == null && file.path != null) {
      final ioFile = File(file.path!);
      bytes = await ioFile.readAsBytes();
    }

    if (bytes != null) {
      return (bytes: bytes, filename: file.name);
    }
  }
  return null;
}
