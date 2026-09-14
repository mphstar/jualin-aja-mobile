import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/repositori.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/bingkai.dart';
import 'package:mobile/widgets/keadaan.dart';

Future<void> _pasang(WidgetTester tester, BentukGalat bentuk) =>
    tester.pumpWidget(
      MaterialApp(
        theme: TemaAplikasi.terang(),
        home: Scaffold(
          body: Bingkai<int>(
            bentukGalat: bentuk,
            ambil: () async =>
                throw const GagalMuat('Tidak bisa terhubung ke server.'),
            rangka: const SizedBox.shrink(),
            isi: (context, nilai) => const Text('isi bingkai'),
          ),
        ),
      ),
    );

void main() {
  testWidgets('bagian layar memakai galat ringkas', (tester) async {
    await _pasang(tester, BentukGalat.padat);
    await tester.pumpAndSettle();

    // Satu baris, tanpa kartu penuh — supaya beberapa bagian yang gagal di
    // satu layar tidak jadi beberapa kartu kembar.
    expect(find.text('Gagal memuat'), findsNothing);
    expect(find.text('Tidak bisa terhubung ke server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('bingkai yang berdiri sendiri memakai kartu', (tester) async {
    await _pasang(tester, BentukGalat.kartu);
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.text('Tidak bisa terhubung ke server.'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('akar tab memakai halaman galat, isi apa pun disembunyikan', (
    tester,
  ) async {
    await _pasang(tester, BentukGalat.halaman);
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('isi bingkai'), findsNothing);

    // Mengisi tab, bukan menyisakan sebagian halaman yang setengah jadi.
    expect(
      tester.getSize(find.byWidgetPredicate((w) => w is Keadaan)).height,
      greaterThan(400),
    );
  });
}
