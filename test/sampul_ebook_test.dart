import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/sampul_ebook.dart';

/// Sampul dipakai di dalam kartu yang tingginya ditentukan isinya — jadi ia
/// harus bisa berdiri sendiri tanpa tinggi dari luar.
void main() {
  testWidgets('sampul teks tidak meledak di dalam tinggi tak terbatas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplikasi.terang(),
        home: const Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 56,
                child: SampulEbook(
                  judul: 'BUMBU DASAR SERBAGUNA',
                  kategori: 'Resep',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final kotak = tester.getSize(find.byType(SampulEbook));
    expect(kotak.width, 56);
    expect(kotak.height.isFinite, isTrue);
    expect(kotak.height, greaterThan(0));
  });
}
