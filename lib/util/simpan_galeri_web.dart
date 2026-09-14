import 'dart:typed_data';

import 'gagal_galeri.dart';

/// Web sengaja tidak didukung: `gal` tidak punya implementasi browser, dan
/// menaruh berkas ke galeri foto bukan sesuatu yang bisa dilakukan tab biasa.
/// Berkas ini juga yang menjaga `package:gal` tetap di luar build web.
/// Layar pembayaran menyembunyikan tombolnya lewat [galeriDidukung].
bool get galeriDidukung => false;

Future<void> simpanGambarKeGaleri(Uint8List bytes, String nama) async {
  throw const GagalGaleri('Galeri tidak didukung di web.');
}
