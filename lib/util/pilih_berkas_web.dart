// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<({Uint8List bytes, String filename})?> pilihBerkasExcel() async {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.xlsx,.xls,.csv';
  uploadInput.click();

  await uploadInput.onChange.first;
  if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
    final file = uploadInput.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    await reader.onLoadEnd.first;
    final result = reader.result;

    if (result is Uint8List) {
      return (bytes: result, filename: file.name);
    } else if (result is List<int>) {
      return (bytes: Uint8List.fromList(result), filename: file.name);
    } else if (result is ByteBuffer) {
      return (bytes: Uint8List.view(result), filename: file.name);
    }
  }
  return null;
}
