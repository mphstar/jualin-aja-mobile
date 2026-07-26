import 'package:flutter/material.dart';

import '../data/model.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';

/// Grafik batang omzet harian — dibangun tangan, tanpa pustaka grafik.
///
/// Alasannya bukan penghematan: satu deret batang tidak butuh mesin grafik
/// seukuran itu, dan pustaka grafik membawa temanya sendiri yang kemudian
/// harus dilawan token demi token. Yang dibutuhkan cuma proporsi tinggi, dan
/// `FractionallySizedBox` sudah melakukannya persis.
///
/// Yang ditandai adalah hari **tertinggi**, bukan hari ini. Hari ini sudah
/// punya tempatnya sendiri di Beranda; yang tidak bisa dilihat di tempat lain
/// adalah hari terbaik dalam periode ini.
class GrafikBatang extends StatelessWidget {
  const GrafikBatang({super.key, required this.titik, this.tinggi = 132});

  final List<TitikHarian> titik;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    if (titik.isEmpty) return const SizedBox.shrink();

    final maks = titik.fold(0, (n, t) => t.omzet > n ? t.omzet : n);
    final indeksMaks = titik.indexWhere((t) => t.omzet == maks);
    final tertinggi = titik[indeksMaks];

    // Label per batang cuma muat sampai tujuh. Lebih dari itu ia jadi bubur
    // dan lebih baik diganti keterangan rentang di bawah grafik.
    final adaLabel = titik.length <= 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (maks > 0) ...[
          Text(
            'Tertinggi ${rupiah(tertinggi.omzet)} · ${tanggal(tertinggi.tanggal)}',
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Jarak.xs),
        ],
        SizedBox(
          height: tinggi,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < titik.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: titik.length > 12 ? 1 : 3,
                    ),
                    child: _Batang(
                      // Hari nol tetap menyisakan guratan tipis. Batang yang
                      // benar-benar hilang terbaca sebagai data yang tidak ada,
                      // padahal artinya toko sepi — dua hal yang sangat berbeda.
                      porsi: maks == 0
                          ? 0.02
                          : (titik[i].omzet / maks).clamp(0.02, 1.0),
                      ditandai: i == indeksMaks && maks > 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xs2),
        if (adaLabel)
          Row(
            children: [
              for (final t in titik)
                Expanded(
                  child: Text(
                    hariPendek(t.tanggal),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: context.teks.labelSmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  tanggal(titik.first.tanggal),
                  style: context.teks.labelSmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  tanggal(titik.last.tanggal),
                  textAlign: TextAlign.right,
                  style: context.teks.labelSmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Batang extends StatelessWidget {
  const _Batang({required this.porsi, required this.ditandai});

  final double porsi;
  final bool ditandai;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: porsi,
        widthFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            color: ditandai ? context.aksen.fokus : context.aksen.isian,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Jarak.xs3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Garis percikan — versi ringkas [GrafikBatang] untuk di dalam panel tinta.
///
/// Angka tunggal "Rp 1.234.000" tidak memberi tahu apakah hari ini bagus.
/// Tujuh batang di bawahnya menjawabnya tanpa satu kata pun, dan memakai
/// bahasa visual yang sama dengan grafik di Laporan — itu yang membuat kedua
/// layar terbaca sebagai satu aplikasi.
class Percikan extends StatelessWidget {
  const Percikan({
    super.key,
    required this.nilai,
    required this.warna,
    required this.warnaAkhir,
    this.tinggi = 34,
  });

  final List<int> nilai;

  /// Warna batang biasa dan batang terakhir (hari ini).
  final Color warna;
  final Color warnaAkhir;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    if (nilai.isEmpty) return const SizedBox.shrink();
    final maks = nilai.fold(0, (n, v) => v > n ? v : n);

    return SizedBox(
      height: tinggi,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < nilai.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    // Hari nol tetap menyisakan guratan. Batang yang hilang
                    // terbaca sebagai data yang tidak ada, padahal artinya
                    // toko sepi — dua hal yang sangat berbeda.
                    heightFactor: maks == 0
                        ? 0.06
                        : (nilai[i] / maks).clamp(0.06, 1.0),
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i == nilai.length - 1 ? warnaAkhir : warna,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bilah proporsi mendatar — dipakai untuk rincian metode pembayaran.
class BilahPorsi extends StatelessWidget {
  const BilahPorsi({super.key, required this.porsi, this.ditandai = false});

  final double porsi;
  final bool ditandai;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Lengkung.bulat),
      child: LinearProgressIndicator(
        value: porsi.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: context.aksen.isian,
        valueColor: AlwaysStoppedAnimation(
          ditandai ? context.aksen.fokus : context.warna.onSurfaceVariant,
        ),
      ),
    );
  }
}
