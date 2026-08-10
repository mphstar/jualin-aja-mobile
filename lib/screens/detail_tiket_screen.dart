import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/bingkai.dart';
import '../widgets/rangka.dart';

/// Halaman Detail Tiket & Balasan Resmi Admin.
class DetailTiketScreen extends StatelessWidget {
  const DetailTiketScreen({super.key, required this.tiketId});

  final int tiketId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
      ),
      body: SafeArea(
        top: false,
        child: Bingkai<TiketDukungan>(
          ambil: () => Repositori.detailTiket(tiketId),
          rangka: const Padding(
            padding: EdgeInsets.all(Jarak.md),
            child: Column(
              children: [
                RangkaPanel(tinggi: 120),
                SizedBox(height: Jarak.md),
                RangkaPanel(tinggi: 160),
              ],
            ),
          ),
          isi: (context, tiket) {
            final Color statusColor = switch (tiket.status) {
              StatusTiketTiketing.terbuka => context.warna.error,
              StatusTiketTiketing.diproses => context.warna.primary,
              StatusTiketTiketing.selesai => const Color(0xFF10B981),
              StatusTiketTiketing.ditutup => context.warna.onSurfaceVariant,
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Jarak.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tiket.nomorTiket,
                        style: context.teks.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Jarak.xs,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Lengkung.kontrol),
                        ),
                        child: Text(
                          tiket.status.label,
                          style: context.teks.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Jarak.xs3),
                  Text(
                    tiket.jenis.label,
                    style: context.teks.bodySmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Jarak.md),

                  // Subjek & Pesan Pengguna
                  Text(
                    tiket.subjek,
                    style: context.teks.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Jarak.xs2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Jarak.md),
                    decoration: BoxDecoration(
                      color: context.warna.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                      border: Border.all(color: context.warna.outlineVariant),
                    ),
                    child: Text(
                      tiket.pesan,
                      style: context.teks.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: Jarak.lg),

                  // Respon Balasan Admin (Jika ada)
                  if (tiket.balasanAdmin != null) ...[
                    Text(
                      'Tanggapan Resmi Admin',
                      style: context.teks.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: Jarak.xs2),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Jarak.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(Lengkung.kontrol),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user,
                                size: 18,
                                color: Color(0xFF047857),
                              ),
                              const SizedBox(width: Jarak.xs3),
                              Text(
                                'Tim Dukungan JualinAja',
                                style: context.teks.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF064E3B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Jarak.xs2),
                          Text(
                            tiket.balasanAdmin!,
                            style: context.teks.bodyMedium?.copyWith(
                              color: const Color(0xFF022C22),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(Jarak.md),
                      decoration: BoxDecoration(
                        color: context.warna.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(Lengkung.kontrol),
                        border: Border.all(color: context.warna.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            color: context.warna.primary,
                          ),
                          const SizedBox(width: Jarak.xs),
                          Expanded(
                            child: Text(
                              'Pesan Anda sudah diterima tim admin. Balasan resmi akan ditanggapi secepatnya.',
                              style: context.teks.bodyMedium?.copyWith(
                                color: context.warna.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
