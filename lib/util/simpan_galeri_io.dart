import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';

import 'gagal_galeri.dart';

/// Platform yang didukung `gal` — daftarnya sama persis dengan platform yang
/// punya galeri foto yang bisa ditulis aplikasi. Linux sengaja tidak termasuk:
/// `gal` hanya mendukungnya lewat plugin federasi tak resmi yang tidak dipasang.
///
/// Getter, bukan `const`: `Platform.isAndroid` baru diketahui saat aplikasi
/// berjalan. Varian stub dan web mengembalikan `false` sebagai konstanta.
bool get galeriDidukung =>
    Platform.isAndroid ||
    Platform.isIOS ||
    Platform.isMacOS ||
    Platform.isWindows;

/// Simpan gambar ke galeri/foto perangkat.
///
/// `nama` tanpa ekstensi — `putImageBytes` menyerahkan penentuan ekstensi ke
/// sistem operasi, berbeda dari `putImage` yang menyalin ekstensi berkas asal.
Future<void> simpanGambarKeGaleri(Uint8List bytes, String nama) async {
  try {
    await Gal.putImageBytes(bytes, name: nama);
  } on GalException catch (e) {
    throw GagalGaleri(_pesan(e.type));
  }
}

String _pesan(GalExceptionType tipe) => switch (tipe) {
  GalExceptionType.accessDenied =>
    'Izin menyimpan ke galeri tidak diberikan. Berikan izinnya lewat '
        'Pengaturan aplikasi, lalu coba lagi.',
  GalExceptionType.notEnoughSpace =>
    'Ruang penyimpanan tidak cukup untuk menyimpan gambar.',
  GalExceptionType.notSupportedFormat =>
    'Format gambar tidak didukung perangkat ini.',
  GalExceptionType.unexpected =>
    'Gambar QRIS tidak berhasil disimpan. Coba lagi.',
};
