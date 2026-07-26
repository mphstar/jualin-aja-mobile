import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'batang.dart';

/// Benda peraga untuk alur pembuka.
///
/// Versi sebelumnya memakai [BlokFoto] bundar — lingkaran abu bertuliskan
/// "Foto belum ada" sebagai hal PERTAMA yang dilihat orang saat membuka
/// aplikasi. Selain jelek, ia jujur ke arah yang salah: yang mestinya
/// diumumkan di layar pembuka adalah apa yang bisa aplikasi ini lakukan,
/// bukan apa yang belum sempat diunggah.
///
/// Gantinya bukan foto stok, tapi **produknya sendiri**: struk, kartu stok,
/// dan grafik — dibangun dari widget yang sama dengan yang dipakai layar
/// sungguhan. Tiga benda yang bentuknya benar-benar berbeda, masing-masing
/// memperagakan janji slide-nya, dan tidak satu pun berpura-pura jadi sesuatu
/// yang belum ada.

/// Bingkai bersama supaya ketiga peraga punya jejak yang sama persis — tanpa
/// ini, carousel-nya melompat setiap kali digeser.
class Peraga extends StatelessWidget {
  const Peraga({super.key, required this.child, this.lebarMaks = 250});

  final Widget child;
  final double lebarMaks;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: lebarMaks),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1 · Struk
// ---------------------------------------------------------------------------

/// Struk mini bertepi gerigi.
///
/// Tepi geriginya bukan hiasan: itu yang membuat benda ini langsung terbaca
/// sebagai struk dan bukan sebagai kartu biasa, tanpa perlu satu kata
/// penjelasan pun.
class PeragaStruk extends StatelessWidget {
  const PeragaStruk({super.key, required this.namaToko, required this.baris});

  final String namaToko;

  /// (nama, jumlah, harga satuan)
  final List<(String, int, int)> baris;

  @override
  Widget build(BuildContext context) {
    final total = baris.fold(0, (n, b) => n + b.$2 * b.$3);

    return Peraga(
      lebarMaks: 232,
      child: PhysicalShape(
        clipper: _KlipStruk(),
        color: context.warna.surfaceContainerLowest,
        elevation: 6,
        shadowColor: context.warna.shadow.withValues(alpha: 0.28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Jarak.sm,
            Jarak.sm,
            Jarak.sm,
            Jarak.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                namaToko.toUpperCase(),
                textAlign: TextAlign.center,
                style: context.teks.titleSmall?.copyWith(letterSpacing: 1.4),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                tanggal(DateTime.now()),
                textAlign: TextAlign.center,
                style: context.teks.labelSmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: Jarak.xs),
              const _GarisPutus(),
              const SizedBox(height: Jarak.xs2),
              for (final (nama, jumlah, harga) in baris) ...[
                _BarisStruk(nama: nama, jumlah: jumlah, harga: harga),
                const SizedBox(height: 5),
              ],
              const SizedBox(height: 3),
              const _GarisPutus(),
              const SizedBox(height: Jarak.xs2),
              Row(
                children: [
                  Expanded(
                    child: Text('TOTAL', style: context.teks.labelSmall),
                  ),
                  Flexible(
                    child: Text(
                      rupiah(total),
                      style: context.teks.titleSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarisStruk extends StatelessWidget {
  const _BarisStruk({
    required this.nama,
    required this.jumlah,
    required this.harga,
  });

  final String nama;
  final int jumlah;
  final int harga;

  @override
  Widget build(BuildContext context) {
    final gaya = context.teks.bodySmall?.copyWith(
      color: context.warna.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        SizedBox(width: 20, child: Text('${jumlah}x', style: gaya)),
        Expanded(
          child: Text(
            nama,
            style: gaya,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Jarak.xs3),
        Text(angka(jumlah * harga), style: gaya),
      ],
    );
  }
}

class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, batas) {
        // Garis putus-putus digambar sendiri: `Divider` tidak punya bentuk
        // ini, dan pada struk sungguhan justru garis inilah yang memisahkan
        // rincian dari total.
        final jumlah = (batas.maxWidth / 6).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            jumlah,
            (_) => SizedBox(
              width: 3,
              height: 1,
              child: ColoredBox(color: context.warna.outline),
            ),
          ),
        );
      },
    );
  }
}

class _KlipStruk extends CustomClipper<Path> {
  static const _gigi = 9.0;
  static const _dalam = 6.0;

  @override
  Path getClip(Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - _dalam);

    var x = size.width;
    var bawah = true;
    while (x > 0) {
      x = (x - _gigi).clamp(0.0, size.width);
      p.lineTo(x, bawah ? size.height : size.height - _dalam);
      bawah = !bawah;
    }
    p
      ..lineTo(0, size.height - _dalam)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> lama) => false;
}

// ---------------------------------------------------------------------------
// 2 · Kartu stok
// ---------------------------------------------------------------------------

/// Tumpukan baris stok — memperagakan bahwa stok ikut turun sendiri.
///
/// Salah satu barisnya sengaja "Habis" dan satu "menipis": keadaan yang
/// membuat orang butuh fitur ini justru keadaan buruk, bukan keadaan rapi.
class PeragaStok extends StatelessWidget {
  const PeragaStok({super.key, required this.baris});

  /// (nama, teks stok, nada) — nada: 0 aman · 1 menipis · 2 habis
  final List<(String, String, int)> baris;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Peraga(
      child: Container(
        padding: const EdgeInsets.all(Jarak.xs),
        decoration: BoxDecoration(
          color: context.warna.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(Lengkung.panel),
          border: Border.all(color: context.warna.outline),
          boxShadow: a.bayanganMengambang,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < baris.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: Jarak.xs2),
                Divider(height: 1, color: context.warna.outline),
                const SizedBox(height: Jarak.xs2),
              ],
              _BarisStok(isi: baris[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarisStok extends StatelessWidget {
  const _BarisStok({required this.isi});

  final (String, String, int) isi;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final (nama, teks, nada) = isi;
    final (latar, depan) = switch (nada) {
      2 => (a.bahayaLembut, a.bahaya),
      1 => (a.peringatanLembut, a.peringatan),
      _ => (a.isian, context.warna.onSurfaceVariant),
    };

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: a.isian,
            borderRadius: BorderRadius.circular(Lengkung.kecil),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.inventory_2_outlined,
            size: 15,
            color: context.warna.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Jarak.xs2),
        Expanded(
          child: Text(
            nama,
            style: context.teks.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Jarak.xs3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: latar,
            borderRadius: BorderRadius.circular(Lengkung.bulat),
          ),
          child: Text(
            teks,
            style: context.teks.labelSmall?.copyWith(
              color: depan,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Laporan
// ---------------------------------------------------------------------------

/// Panel tinta berisi omzet dan tujuh batang — kembaran kecil panel fokus di
/// Beranda, jadi bentuk yang dijanjikan di layar pembuka betul-betul yang
/// ditemukan setelah masuk.
class PeragaLaporan extends StatelessWidget {
  const PeragaLaporan({super.key, required this.omzet, required this.deret});

  final int omzet;
  final List<int> deret;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Peraga(
      child: Container(
        padding: const EdgeInsets.all(Jarak.sm),
        decoration: BoxDecoration(
          color: a.fokus,
          borderRadius: BorderRadius.circular(Lengkung.panel),
          boxShadow: a.bayanganMengambang,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'OMZET 7 HARI',
              style: context.teks.labelSmall?.copyWith(
                color: a.atasFokusRedup,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: Jarak.xs3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                rupiah(omzet),
                style: context.teks.headlineSmall?.copyWith(
                  color: a.atasFokus,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: Jarak.xs),
            Percikan(
              nilai: deret,
              warna: a.atasFokusRedup.withValues(alpha: 0.35),
              warnaAkhir: a.atasFokus,
              tinggi: 46,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tanda merek
// ---------------------------------------------------------------------------

/// Petak tinta berikon toko, dengan wordmark opsional.
///
/// Satu bentuk yang sama dipakai di kepala rail dan di layar masuk, jadi
/// perpindahan dari luar ke dalam aplikasi membawa satu benda yang dikenali.
class TandaMerek extends StatelessWidget {
  const TandaMerek({super.key, this.ukuran = 44, this.berlabel = false});

  final double ukuran;
  final bool berlabel;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final petak = Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: a.fokus,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        size: ukuran * 0.5,
        color: a.atasFokus,
      ),
    );

    if (!berlabel) return petak;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        petak,
        const SizedBox(width: Jarak.xs2),
        Flexible(
          child: Text(
            'Kasir POS',
            style: context.teks.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Penunjuk langkah
// ---------------------------------------------------------------------------

/// Penunjuk langkah untuk layar pertanyaan.
///
/// Tanpa ini, dua layar pertanyaan yang bentuknya mirip terbaca seperti satu
/// layar yang gagal berpindah — dan pengguna tidak punya cara tahu apakah
/// masih ada sepuluh lagi di depan.
class PenunjukLangkah extends StatelessWidget {
  const PenunjukLangkah({super.key, required this.langkah, required this.dari});

  final int langkah;
  final int dari;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= dari; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: Gerak.sedang,
              curve: Gerak.keluar,
              height: 4,
              decoration: BoxDecoration(
                color: i <= langkah
                    ? context.warna.onSurface
                    : context.aksen.isian,
                borderRadius: BorderRadius.circular(Lengkung.bulat),
              ),
            ),
          ),
        ],
        const SizedBox(width: Jarak.xs),
        Text(
          '$langkah/$dari',
          style: context.teks.labelSmall?.copyWith(
            color: context.warna.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
