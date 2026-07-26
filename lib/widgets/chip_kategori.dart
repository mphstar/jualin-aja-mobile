import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Baris kategori berupa lingkaran berikon, digulir mendatar.
///
/// Bentuk lingkaran 56 px dipilih menggantikan chip teks datar (~32 px) karena
/// ia memberi target sentuh jauh lebih besar — dan di tangan kasir yang sedang
/// buru-buru, itu bukan urusan gaya.
///
/// Terpilih ditandai **isian tinta**, bukan warna. Sama seperti tombol utama:
/// satu sinyal "ini yang aktif" untuk seluruh aplikasi.
class BarisKategori extends StatelessWidget {
  const BarisKategori({
    super.key,
    required this.item,
    required this.terpilih,
    required this.onPilih,
  });

  /// (id, label, ikon). `id` null berarti "semua".
  final List<(String?, String, IconData)> item;
  final String? terpilih;
  final ValueChanged<String?> onPilih;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: item.length,
        separatorBuilder: (_, _) => const SizedBox(width: Jarak.xs2),
        itemBuilder: (context, i) {
          final (id, label, ikon) = item[i];
          return _Bulatan(
            label: label,
            ikon: ikon,
            aktif: terpilih == id,
            onTekan: () => onPilih(id),
          );
        },
      ),
    );
  }
}

class _Bulatan extends StatelessWidget {
  const _Bulatan({
    required this.label,
    required this.ikon,
    required this.aktif,
    required this.onTekan,
  });

  final String label;
  final IconData ikon;
  final bool aktif;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: aktif,
      child: SizedBox(
        width: 70,
        child: InkWell(
          onTap: onTekan,
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Gerak.sedang,
                curve: Gerak.keluar,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: aktif
                      ? context.aksen.fokus
                      : context.warna.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: aktif ? context.aksen.fokus : context.warna.outline,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  ikon,
                  size: 24,
                  color: aktif
                      ? context.aksen.atasFokus
                      : context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.teks.bodySmall?.copyWith(
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                  color: aktif
                      ? context.warna.onSurface
                      : context.warna.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
