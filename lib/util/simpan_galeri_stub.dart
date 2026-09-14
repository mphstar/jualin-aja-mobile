import 'dart:typed_data';

import 'gagal_galeri.dart';

/// Galeri tidak tersedia di platform ini.
bool get galeriDidukung => false;

Future<void> simpanGambarKeGaleri(Uint8List bytes, String nama) async {
  throw const GagalGaleri('Galeri tidak didukung di platform ini.');
}
