import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/model.dart';
import 'package:mobile/data/populer.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/penanda_populer.dart';

/// Lencana "Terpopuler" dipakai dua layar (Pustaka dan Klaim gratis), dan
/// lapisan jaringan `masuk()` masih rusak sehingga tes widget alur tidak bisa
/// dipakai di proyek ini. Keputusannya karena itu diuji langsung di sini.

Ebook _ebook({required String id, int jumlahUnduhan = 0}) => Ebook(
  id: id,
  jenis: JenisKonten.resep,
  judul: 'Konten $id',
  kategori: 'Minuman',
  deskripsi: 'Deskripsi $id',
  jumlahHalaman: 40,
  ukuranMb: 3.2,
  jumlahUnduhan: jumlahUnduhan,
);

/// Pasang [PenandaPopuler] di kolom teks selebar kartu Pustaka pada layar
/// 320 px: 320 − 16·2 (tepi halaman) − 4·2 (margin kartu) − 12·2 (padding
/// kartu) − 92 (sampul) − 12 (jarak antar kolom) = 152 px.
Future<void> _pasangPenanda(
  WidgetTester tester, {
  required int jumlahUnduhan,
  required bool populer,
}) => tester.pumpWidget(
  MaterialApp(
    theme: TemaAplikasi.terang(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 152,
          child: PenandaPopuler(
            jumlahUnduhan: jumlahUnduhan,
            populer: populer,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('idTerpopuler', () {
    test('katalog kosong tidak menghasilkan pemenang', () {
      expect(idTerpopuler([]), isEmpty);
    });

    test('belum ada yang dibuka berarti tidak ada yang terpopuler', () {
      // Lencana tanpa dasar lebih buruk daripada tidak ada lencana: ia menandai
      // konten yang justru belum pernah dibuka siapa pun.
      final hasil = idTerpopuler([
        _ebook(id: '1'),
        _ebook(id: '2'),
        _ebook(id: '3'),
      ]);

      expect(hasil, isEmpty);
    });

    test('konten tanpa buka tidak ikut menempel di ekor daftar', () {
      // Katalog isinya baru dua konten dan hanya satu yang pernah dibuka.
      // "Terpopuler" harus satu, bukan dua yang kedua cuma numpang.
      final hasil = idTerpopuler([
        _ebook(id: '1', jumlahUnduhan: 7),
        _ebook(id: '2'),
      ]);

      expect(hasil, {'1'});
    });

    test('mengambil tiga terbanyak', () {
      final hasil = idTerpopuler([
        _ebook(id: 'a', jumlahUnduhan: 4),
        _ebook(id: 'b', jumlahUnduhan: 90),
        _ebook(id: 'c', jumlahUnduhan: 12),
        _ebook(id: 'd', jumlahUnduhan: 31),
        _ebook(id: 'e', jumlahUnduhan: 1),
      ]);

      expect(hasil, {'b', 'd', 'c'});
    });

    test('seri diselesaikan urutan daftar, jadi tetap antar pemuatan', () {
      // Urutan `sort` di Dart tidak dijamin stabil. Tanpa pemecah seri
      // eksplisit, pemenang seri bisa berganti-ganti dan lencananya terlihat
      // seperti berpindah sendiri.
      final hasil = idTerpopuler([
        _ebook(id: 'pertama', jumlahUnduhan: 10),
        _ebook(id: 'kedua', jumlahUnduhan: 10),
        _ebook(id: 'ketiga', jumlahUnduhan: 10),
        _ebook(id: 'keempat', jumlahUnduhan: 10),
      ]);

      expect(hasil, {'pertama', 'kedua', 'ketiga'});
    });

    test('kurang dari tiga yang dibuka berarti semuanya masuk', () {
      final hasil = idTerpopuler([
        _ebook(id: 'a', jumlahUnduhan: 2),
        _ebook(id: 'b'),
        _ebook(id: 'c', jumlahUnduhan: 5),
      ]);

      expect(hasil, {'a', 'c'});
    });
  });

  group('PenandaPopuler', () {
    testWidgets('menampilkan lencana dan angka buka di kolom tersempit', (
      tester,
    ) async {
      await _pasangPenanda(tester, jumlahUnduhan: 1234, populer: true);

      expect(tester.takeException(), isNull);
      expect(find.text('Terpopuler'), findsOneWidget);
      expect(find.text('1234× dibuka'), findsOneWidget);
    });

    testWidgets('tanpa lencana, angkanya tetap ada', (tester) async {
      // Angka buka berguna tanpa lencana: ia yang membuat "Terpopuler" pada
      // konten lain bisa dibandingkan, bukan cuma dipercaya.
      await _pasangPenanda(tester, jumlahUnduhan: 0, populer: false);

      expect(tester.takeException(), isNull);
      expect(find.text('Terpopuler'), findsNothing);
      expect(find.text('0× dibuka'), findsOneWidget);
    });
  });
}
