import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Kartu berisi baris-baris berpemisah.
///
/// Dipakai di Produk, Riwayat, Laporan, dan Akun. Satu bentuk untuk semua
/// daftar adalah alasan halaman-halaman itu terbaca sebagai satu aplikasi
/// walau isinya tidak berhubungan.
class KartuDaftar extends StatelessWidget {
  const KartuDaftar({super.key, required this.anak});

  final List<Widget> anak;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < anak.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.warna.outline),
            anak[i],
          ],
        ],
      ),
    );
  }
}

/// Judul bagian di dalam halaman: label kecil di kiri, aksi opsional di kanan.
///
/// Labelnya huruf besar dan redup karena ia penanda, bukan tujuan — kalau ia
/// sepekat judul kartu di bawahnya, keduanya bersaing dan mata tidak tahu mana
/// yang lebih penting.
class JudulBagian extends StatelessWidget {
  const JudulBagian(this.teks, {super.key, this.aksi});

  final String teks;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Jarak.xs2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teks.toUpperCase(),
              style: context.teks.labelSmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?aksi,
        ],
      ),
    );
  }
}

/// Kepala halaman — judul + keterangan + aksi opsional.
class KepalaHalaman extends StatelessWidget {
  const KepalaHalaman({
    super.key,
    required this.judul,
    this.keterangan,
    this.aksi,
  });

  final String judul;
  final String? keterangan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Jarak.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: context.teks.headlineSmall),
                if (keterangan != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    keterangan!,
                    style: context.teks.bodyMedium?.copyWith(
                      color: context.warna.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Expanded, bukan Spacer: pada 320 px judul dan aksi berukuran alami
          // sudah cukup untuk saling mendorong keluar layar.
          if (aksi != null) ...[const SizedBox(width: Jarak.xs2), aksi!],
        ],
      ),
    );
  }
}

/// Baris daftar baku: ikon/petak di kiri, dua baris teks di tengah, nilai di
/// kanan.
class BarisDaftar extends StatelessWidget {
  const BarisDaftar({
    super.key,
    required this.awalan,
    required this.judul,
    this.keterangan,
    this.warnaKeterangan,
    this.akhiran,
    this.bawahAkhiran,
    this.onTekan,
  });

  final Widget awalan;
  final String judul;
  final String? keterangan;
  final Color? warnaKeterangan;
  final String? akhiran;
  final Widget? bawahAkhiran;
  final VoidCallback? onTekan;

  @override
  Widget build(BuildContext context) {
    final isi = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Jarak.xs,
        vertical: Jarak.xs,
      ),
      child: Row(
        children: [
          awalan,
          const SizedBox(width: Jarak.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: context.teks.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (keterangan != null)
                  Text(
                    keterangan!,
                    style: context.teks.bodySmall?.copyWith(
                      color: warnaKeterangan ?? context.warna.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (akhiran != null || bawahAkhiran != null) ...[
            const SizedBox(width: Jarak.xs2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (akhiran != null)
                  Text(
                    akhiran!,
                    style: context.teks.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (bawahAkhiran != null) ...[
                  const SizedBox(height: 3),
                  bawahAkhiran!,
                ],
              ],
            ),
          ],
        ],
      ),
    );

    if (onTekan == null) return isi;
    return InkWell(onTap: onTekan, child: isi);
  }
}
