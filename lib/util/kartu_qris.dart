import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/model.dart';
import 'format.dart';

/// Gambar yang disimpan selalu selebar ini, dalam piksel — tidak ikut ukuran
/// layar. Ponsel kecil dan tablet menghasilkan berkas yang sama.
const double _lebar = 1000;

/// Tepi putih di kiri-kanan keterangan dan di dasar gambar. Zona sunyi kode
/// QR-nya **bukan** ini — lihat [_modulSunyi].
const double _tepi = 56;

/// Jarak antar baris keterangan.
const double _jarak = 14;

/// Lebar zona sunyi di sekeliling kode QR, dalam satuan modul.
///
/// Spesifikasi QR (ISO/IEC 18004) meminta minimal 4 modul. Kalau kurang,
/// pemindai kehilangan batas simbolnya — dan itulah yang dulu terjadi: kode QR
/// di layar terbaca karena duduk di dalam kartu berpadding, sementara gambar
/// hasil unduhan punya zona sunyi cuma 3,3 modul sehingga tidak terbaca.
const int _modulSunyi = 4;

const ui.Color _tinta = ui.Color(0xFF111111);
const ui.Color _tintaRedup = ui.Color(0xFF5F6368);

/// Sisi kode QR dalam piksel, beserta ukuran satu modulnya.
///
/// Sisi QR **wajib** kelipatan bulat jumlah modul. Kalau tidak, tiap tepi modul
/// mendarat di tengah piksel dan pemindai harus menebak ambang hitam-putihnya.
/// Karena itu ukurannya dihitung sendiri di sini, bukan diserahkan ke painter
/// yang membulatkan ukuran modul ke 0,5 terdekat.
({int modul, int sisi}) _ukuranKode(int jumlahModul) {
  // Dicari dari yang terbesar lalu diturunkan: kode QR sebesar mungkin supaya
  // pemindai dapat piksel sebanyak mungkin, tapi zona sunyinya tidak boleh
  // turun di bawah [_modulSunyi]. Zona sunyinya diukur dari tepi gambar, jadi
  // sisa lebar di kiri dan kanan QR itulah yang dihitung.
  var modul = (_lebar / jumlahModul).floor();
  while (modul > 1 &&
      (_lebar - modul * jumlahModul) / 2 < _modulSunyi * modul) {
    modul--;
  }

  return (modul: modul, sisi: modul * jumlahModul);
}

/// Gambar kode QRIS beserta keterangan tagihan, sebagai PNG.
///
/// Kodenya digambar di sini, bukan diambil dari layanan mana pun: muatan QRIS
/// memuat identitas merchant dan nominal, jadi ia tidak boleh singgah di server
/// orang lain. Keterangannya — nama produk, nomor invoice, nominal, tenggat —
/// yang membuat gambar ini berguna sebagai bukti kalau pembayaran bermasalah.
///
/// Gaya teksnya sengaja `TextStyle` polos tanpa `fontFamily`, bukan
/// `google_fonts`: gambar ini artefak yang keluar dari aplikasi, dan font dari
/// jaringan tidak diinginkan di sini — juga tidak tersedia di dalam tes.
Future<Uint8List> gambarQris(Tagihan tagihan, String qrString) async {
  // Versi QR-nya ditentukan di sini, bukan di dalam painter, karena jumlah
  // modulnya dipakai untuk menghitung geometri. Lewat `QrValidator` angkanya
  // pasti, bukan tebakan — dan `QrPainter.withQr` memakai objek yang sama
  // persis, jadi yang digambar dijamin sebentuk dengan yang diukur.
  final hasil = QrValidator.validate(
    data: qrString,
    version: QrVersions.auto,
    // Sama dengan QR di layar (`QrImageView` juga memakai L).
    errorCorrectionLevel: QrErrorCorrectLevel.L,
  );
  if (!hasil.isValid) {
    throw StateError('Muatan QRIS tidak bisa digambar');
  }

  final qr = hasil.qrCode!;
  final ukuran = _ukuranKode(qr.moduleCount);

  final kode = await QrPainter.withQr(
    qr: qr,
    gapless: true,
    // Latar putihnya digambar kanvas di bawah, bukan oleh painter: `color` dan
    // `emptyColor` sudah usang, dan modul kosong kini memang dibiarkan tembus
    // pandang supaya pemanggil yang menentukan latarnya.
    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _tinta),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: _tinta,
    ),
  ).toImage(ukuran.sisi.toDouble());

  final keterangan = <TextPainter>[
    _teks('JualinAja', 48, FontWeight.w700),
    _teks(tagihan.nomorInvoice, 34, FontWeight.w400, warna: _tintaRedup),
    _teks(rupiah(tagihan.nominal), 42, FontWeight.w600),
    _teks(
      'Bayar sebelum ${tanggal(tagihan.batasBayar)}, '
      '${jam(tagihan.batasBayar)}',
      32,
      FontWeight.w400,
      warna: _tintaRedup,
    ),
  ];

  final lebarTeks = _lebar - _tepi * 2;
  for (final t in keterangan) {
    t.layout(maxWidth: lebarTeks);
  }

  final tinggiKeterangan =
      keterangan.fold<double>(0, (n, t) => n + t.height) +
      _jarak * (keterangan.length - 1);

  // Kode QR ditaruh di tengah bidang persegi selebar gambar, jadi zona sunyinya
  // sama lebar di kiri, kanan, dan atas. Keterangan mulai satu zona sunyi di
  // bawahnya, supaya teksnya tidak menyerobot zona sunyi yang bawah.
  final sunyi = ((_lebar - ukuran.sisi) / 2).floor();
  final yKeterangan = (ukuran.sisi + sunyi * 2).toDouble();
  final tinggi = yKeterangan + tinggiKeterangan + _tepi;

  final perekam = ui.PictureRecorder();
  final kanvas = ui.Canvas(perekam);

  kanvas.drawRect(
    ui.Rect.fromLTWH(0, 0, _lebar, tinggi),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  kanvas.drawImage(kode, ui.Offset(sunyi.toDouble(), sunyi.toDouble()), ui.Paint());

  var y = yKeterangan;
  for (final t in keterangan) {
    t.paint(kanvas, ui.Offset(_tepi, y));
    y += t.height + _jarak;
  }

  final gambar = await perekam.endRecording().toImage(
    _lebar.round(),
    tinggi.ceil(),
  );
  final data = await gambar.toByteData(format: ui.ImageByteFormat.png);

  kode.dispose();
  gambar.dispose();

  if (data == null) {
    throw StateError('Gambar QRIS tidak bisa dikodekan jadi PNG');
  }

  return data.buffer.asUint8List();
}

TextPainter _teks(
  String isi,
  double ukuran,
  FontWeight tebal, {
  ui.Color warna = _tinta,
}) => TextPainter(
  text: TextSpan(
    text: isi,
    style: TextStyle(
      fontSize: ukuran,
      fontWeight: tebal,
      color: warna,
      height: 1.3,
    ),
  ),
  textDirection: TextDirection.ltr,
);
