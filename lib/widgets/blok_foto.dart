import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Tempat foto produk.
///
/// Selama `url` masih kosong, ia menampilkan penanda yang JELAS berbunyi
/// "foto belum ada" — bukan kotak abu polos. Bedanya penting: kotak polos
/// terbaca sebagai gambar yang gagal dimuat, dan itu tampak seperti bug.
/// Penanda yang menyebut dirinya sendiri terbaca sebagai pekerjaan yang
/// memang belum selesai.
class BlokFoto extends StatelessWidget {
  const BlokFoto({
    super.key,
    this.url,
    this.ikon = Icons.photo_camera_outlined,
    this.radius = Lengkung.kecil,
    this.tampilkanLabel = true,
  });

  final String? url;
  final IconData ikon;
  final double radius;
  final bool tampilkanLabel;

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(url!, fit: BoxFit.cover),
      );
    }

    return LayoutBuilder(
      builder: (context, batas) {
        // Label hanya muat kalau bloknya cukup tinggi; di bawah itu ikon saja.
        final muatLabel = tampilkanLabel && batas.maxHeight >= 76;
        return Container(
          decoration: BoxDecoration(
            color: context.aksen.kartuAlt,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: context.aksen.garisRedup),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, size: 22, color: context.warna.onSurfaceVariant),
              if (muatLabel) ...[
                const SizedBox(height: 4),
                Text(
                  'Foto belum ada',
                  style: context.teks.labelSmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
