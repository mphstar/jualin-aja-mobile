import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Sampul ebook yang dibangun dari huruf, bukan dari gambar.
///
/// Versi sebelumnya memakai petak foto kosong berikon buku — enam kotak abu
/// yang sama persis berjajar ke bawah. Itu penyebab daftarnya terasa mati:
/// bukan kurang hiasan, tapi tidak ada satu pun yang membedakan satu baris
/// dari baris lainnya.
///
/// Di sini pembedanya adalah **judulnya sendiri**. "50 RESEP MINUMAN" dan
/// "BUMBU DASAR SERBAGUNA" membentuk blok huruf yang bentuknya sudah sangat
/// berbeda, tanpa perlu satu warna pun ditambahkan — yang penting di sistem
/// monokrom, karena kroma di sini milik status.
///
/// Ini juga jujur: ia tidak berpura-pura jadi foto sampul yang belum ada.
class SampulEbook extends StatelessWidget {
  const SampulEbook({
    super.key,
    required this.judul,
    required this.kategori,
    this.sudahDiunduh = false,
  });

  final String judul;
  final String kategori;
  final bool sudahDiunduh;

  /// Tiga kata pertama. Judul utuh di sampul sekecil ini jadi bubur; tiga kata
  /// cukup untuk membedakan satu buku dari yang lain.
  String get _ringkas {
    final kata = judul.split(RegExp(r'\s+'));
    return kata.take(3).join('\n').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Container(
      decoration: BoxDecoration(
        color: a.fokus,
        borderRadius: BorderRadius.circular(Lengkung.kecil),
      ),
      padding: const EdgeInsets.all(Jarak.xs2),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kategori.toUpperCase(),
                style: context.teks.labelSmall?.copyWith(
                  color: a.atasFokusRedup,
                  fontSize: 8,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Jarak.xs2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: Text(
                    _ringkas,
                    style: context.teks.titleSmall?.copyWith(
                      color: a.atasFokus,
                      height: 1.1,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              // Garis penutup — meniru rusuk sampul buku, dan memberi dasar
              // yang tegas supaya bloknya tidak terlihat mengambang.
              Container(
                height: 2,
                width: 26,
                decoration: BoxDecoration(
                  color: a.atasFokus,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          if (sudahDiunduh)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: a.sukses,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.check, size: 12, color: a.atasFokus),
              ),
            ),
        ],
      ),
    );
  }
}
