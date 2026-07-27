import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Tanda merek dan penunjuk langkah untuk alur pembuka.
///
/// Berkas ini pernah juga berisi tiga "peraga": replika struk, kartu stok, dan
/// panel omzet yang dibangun dari widget layar sungguhan. Gagasannya benar —
/// layar pembuka memperagakan produk, bukan menunggu foto — tapi hasilnya
/// terbaca seperti tangkapan layar yang dikecilkan, bukan seperti gambar.
///
/// Penggantinya ada di `ilustrasi.dart`: ilustrasi garis yang boleh
/// melebih-lebihkan yang penting dan membuang sisanya. Aturannya tidak berubah,
/// hanya cara memenuhinya: tetap monokrom, tetap menggambarkan janji slide-nya,
/// dan tetap tidak pernah memamerkan penanda foto kosong.

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
