import 'package:flutter/material.dart';

import 'kebijakan_privasi_screen.dart';
import 'syarat_ketentuan_screen.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/ikon_kotak.dart';
import '../widgets/ilustrasi.dart';
import '../widgets/kartu.dart';

/// Halaman Tentang Aplikasi (App Info, Version, Terms & Privacy).
class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang aplikasi'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Jarak.md),
          child: Column(
            children: [
              const SizedBox(height: Jarak.sm),
              // Branding / Logo Aplikasi
              const Ilustrasi(gambar: GambarIlustrasi.etalase, lebarMaks: 180),
              const SizedBox(height: Jarak.sm),
              Text(
                'JualinAja POS',
                style: context.teks.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Jarak.xs3),
              Text(
                'Versi 1.0.0 (Build 100)',
                style: context.teks.bodyMedium?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Jarak.md),

              // Deskripsi Singkat Aplikasi
              Container(
                padding: const EdgeInsets.all(Jarak.md),
                decoration: BoxDecoration(
                  color: context.warna.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(Lengkung.panel),
                  border: Border.all(color: context.warna.outlineVariant),
                ),
                child: Text(
                  'JualinAja POS adalah sistem kasir Point of Sale modern yang dirancang untuk mempermudah operasional pencatatan penjualan, kelola stok barang, cetak struk, dan laporan keuangan toko, kafe, warung, dan UMKM di Indonesia.',
                  textAlign: TextAlign.center,
                  style: context.teks.bodyMedium?.copyWith(
                    height: 1.45,
                    color: context.warna.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: Jarak.md),

              // Menu Kebijakan & Syarat
              KartuDaftar(
                anak: [
                  BarisDaftar(
                    awalan: const IkonKotak(Icons.description_outlined, ukuran: 36),
                    judul: 'Syarat & Ketentuan Layanan',
                    bawahAkhiran: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: context.warna.onSurfaceVariant,
                    ),
                    onTekan: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SyaratKetentuanScreen(),
                      ),
                    ),
                  ),
                  BarisDaftar(
                    awalan: const IkonKotak(Icons.privacy_tip_outlined, ukuran: 36),
                    judul: 'Kebijakan Privasi',
                    bawahAkhiran: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: context.warna.onSurfaceVariant,
                    ),
                    onTekan: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const KebijakanPrivasiScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Jarak.lg),

              // Copyright
              Text(
                '© 2026 JualinAja Inc. Hak Cipta Dilindungi.',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
