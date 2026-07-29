import 'dart:io';
import 'dart:typed_data';

Future<void> simpanBerkasKePerangkat(Uint8List bytes, String namaBerkas) async {
  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$namaBerkas');
  await file.writeAsBytes(bytes);
}
