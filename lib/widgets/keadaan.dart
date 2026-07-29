import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Keadaan kosong dan keadaan galat.
///
/// Keduanya memakai bentuk yang sama karena keduanya menjawab pertanyaan yang
/// sama dari pengguna: *"kenapa layarnya kosong, dan apa yang harus saya
/// lakukan?"* Yang membedakan cuma nada dan tombolnya.
///
/// Aturan yang dipegang: **judul menyebut keadaan, keterangan menyebut
/// penyebab, tombol menyebut kata kerja.** "Belum ada apa-apa di sini" tanpa
/// jalan keluar adalah jalan buntu yang sopan.
class Keadaan extends StatelessWidget {
  const Keadaan({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
    this.labelAksi,
    this.onAksi,
    this.aksiWidget,
    this.nada = NadaKeadaan.tenang,
  });

  /// Keadaan galat — bingkai kemerahan, tombol "Coba lagi".
  const factory Keadaan.galat({
    Key? key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) = _KeadaanGalat;

  final IconData ikon;
  final String judul;
  final String keterangan;
  final String? labelAksi;
  final VoidCallback? onAksi;
  final Widget? aksiWidget;
  final NadaKeadaan nada;

  @override
  Widget build(BuildContext context) {
    final bahaya = nada == NadaKeadaan.bahaya;
    final warnaIkon = bahaya
        ? context.aksen.bahaya
        : context.warna.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Jarak.md,
        vertical: Jarak.lg,
      ),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        border: Border.all(
          color: bahaya
              ? context.aksen.bahaya.withValues(alpha: 0.3)
              : context.warna.outline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bahaya ? context.aksen.bahayaLembut : context.aksen.isian,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(ikon, size: 24, color: warnaIkon),
          ),
          const SizedBox(height: Jarak.xs),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: context.teks.titleMedium,
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              keterangan,
              textAlign: TextAlign.center,
              style: context.teks.bodyMedium?.copyWith(
                color: context.warna.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
          if (aksiWidget != null) ...[
            const SizedBox(height: Jarak.sm),
            aksiWidget!,
          ] else if (labelAksi != null && onAksi != null) ...[
            const SizedBox(height: Jarak.sm),
            OutlinedButton(onPressed: onAksi, child: Text(labelAksi!)),
          ],
        ],
      ),
    );
  }
}

enum NadaKeadaan { tenang, bahaya }

class _KeadaanGalat extends Keadaan {
  const _KeadaanGalat({
    super.key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) : super(
         ikon: Icons.cloud_off_outlined,
         judul: 'Gagal memuat',
         keterangan: pesan,
         labelAksi: 'Coba lagi',
         onAksi: onCobaLagi,
         nada: NadaKeadaan.bahaya,
       );
}
