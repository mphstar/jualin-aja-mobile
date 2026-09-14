import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/keadaan.dart';

/// Kartu keadaan: satu-satunya `Container` berbingkai di dalam panel.
final _kartu = find.byWidgetPredicate(
  (w) => w is Container && (w.decoration as BoxDecoration?)?.border != null,
);

Future<void> _pasang(WidgetTester tester, Widget anak) => tester.pumpWidget(
  MaterialApp(
    theme: TemaAplikasi.terang(),
    home: Scaffold(body: ListView(children: [anak])),
  ),
);

void main() {
  testWidgets('galat: bingkai biasa, aksi utama, lebar dibatasi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await _pasang(
      tester,
      Keadaan.galat(
        pesan: 'Tidak bisa terhubung ke server.',
        onCobaLagi: () {},
      ),
    );

    // Ruangnya 900 px. Kartunya tetap selebar baca dan duduk di tengah —
    // bukan bidang putih selebar layar.
    expect(tester.getSize(_kartu).width, lessThanOrEqualTo(420));
    expect(tester.getCenter(_kartu).dx, closeTo(450, 1));

    // Bingkainya garis biasa, bukan merah: kroma hanya untuk status.
    final border = (_kartu.evaluate().single.widget as Container).decoration!;
    expect((border as BoxDecoration).border, isA<Border>());
    expect(
      (border.border! as Border).top.color,
      TemaAplikasi.terang().colorScheme.outline,
    );

    // "Coba lagi" satu-satunya jalan keluar, jadi ia aksi utama.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('galat ringkas: satu baris, tanpa judul', (tester) async {
    await _pasang(
      tester,
      Keadaan.galatPadat(
        pesan: 'Tidak bisa terhubung ke server.',
        onCobaLagi: () {},
      ),
    );

    // Tingginya sebaris; judulnya dibuang supaya tidak menumpuk.
    expect(find.text('Gagal memuat'), findsNothing);
    expect(find.text('Tidak bisa terhubung ke server.'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    expect(tester.getSize(_kartu).height, lessThan(80));
  });

  testWidgets('galat halaman: mengisi tab, tanpa kartu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplikasi.terang(),
        home: Scaffold(
          body: Keadaan.galatHalaman(
            pesan: 'Tidak bisa terhubung ke server.',
            onCobaLagi: () {},
          ),
        ),
      ),
    );

    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    // Tanpa panel berbingkai: tidak ada lagi yang perlu dibingkai.
    expect(_kartu, findsNothing);
    // Mengisi tab, bukan sepotong kecil di tengahnya.
    expect(
      tester.getSize(find.byWidgetPredicate((w) => w is Keadaan)).height,
      greaterThan(400),
    );
  });

  testWidgets('kosong: aksinya tetap tombol sekunder', (tester) async {
    await _pasang(
      tester,
      Keadaan(
        ikon: Icons.category_outlined,
        judul: 'Belum ada kategori',
        keterangan: 'Tambahkan kategori pertama.',
        labelAksi: 'Tambah kategori',
        onAksi: () {},
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
