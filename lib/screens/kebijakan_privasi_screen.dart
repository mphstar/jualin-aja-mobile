import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Halaman Kebijakan Privasi (Privacy Policy).
class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Jarak.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kebijakan Privasi',
                style: context.teks.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Jarak.xs3),
              Text(
                'Terakhir diperbarui: 10 Agustus 2026',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Jarak.md),
              const _PoinPrivasi(
                ikon: Icons.security_rounded,
                judul: 'Komitmen Perlindungan Data',
                isi:
                    'JualinAja POS berkomitmen penuh untuk melindungi privasi dan keamanan data pemilik toko. '
                    'Kebijakan ini menjelaskan bagaimana kami mengumpulkan, mengelola, dan melindungi data pribadi serta transaksi Anda.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinPrivasi(
                ikon: Icons.dataset_rounded,
                judul: 'Informasi yang Kami Kumpulkan',
                isi:
                    'Kami mengumpulkan informasi akun (Nama, Email, No. Telepon), informasi usaha (Nama Toko, Alamat, Jenis Usaha), '
                    'serta data operasional kasir (Katalog Produk, Stok, Riwayat Transaksi) untuk menjalankan fungsi aplikasi POS.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinPrivasi(
                ikon: Icons.settings_suggest_rounded,
                judul: 'Penggunaan Data Toko',
                isi:
                    'Data transaksi toko hanya digunakan untuk memproses transaksi kasir Anda, menyajikan laporan keuangan internal usaha Anda, '
                    'dan menyinkronkan data antar perangkat yang terhubung dengan akun Anda.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinPrivasi(
                ikon: Icons.lock_rounded,
                judul: 'Keamanan & Enkripsi',
                isi:
                    'Seluruh transmisi data antara aplikasi mobile dan server backend dilindungi menggunakan protokol enkripsi standar industri (SSL/TLS). '
                    'Kami tidak pernah menjual data bisnis Anda kepada pihak ketiga untuk kepentingan komersial.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinPrivasi(
                ikon: Icons.account_circle_rounded,
                judul: 'Hak Pengguna atas Data',
                isi:
                    'Anda berhak memperbarui, mengoreksi, atau mengajukan penghapusan data akun dan toko Anda kapan saja melalui '
                    'layanan dukungan pelanggan kami di support@jualinaja.id.',
              ),
              const SizedBox(height: Jarak.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoinPrivasi extends StatelessWidget {
  const _PoinPrivasi({
    required this.ikon,
    required this.judul,
    required this.isi,
  });

  final IconData ikon;
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ikon,
                size: 22,
                color: context.warna.primary,
              ),
              const SizedBox(width: Jarak.xs2),
              Expanded(
                child: Text(
                  judul,
                  style: context.teks.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.xs),
          Text(
            isi,
            style: context.teks.bodyMedium?.copyWith(
              color: context.warna.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
