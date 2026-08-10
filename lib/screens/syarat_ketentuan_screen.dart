import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Halaman Syarat & Ketentuan Layanan.
class SyaratKetentuanScreen extends StatelessWidget {
  const SyaratKetentuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syarat & Ketentuan'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Jarak.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syarat & Ketentuan Layanan',
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
              const _PoinKetentuan(
                nomor: '1',
                judul: 'Ketentuan Umum & Pendaftaran',
                isi:
                    'Selamat datang di JualinAja POS. Dengan mendaftar dan menggunakan aplikasi ini, Anda menyetujui seluruh ketentuan layanan yang berlaku. Pengguna wajib memberikan data yang valid saat pendaftaran akun toko.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinKetentuan(
                nomor: '2',
                judul: 'Paket Langganan & Batas Fitur',
                isi:
                    'JualinAja POS menyediakan 3 versi langganan: Gratis, Trial (Uji Coba), dan Langganan (Berbayar). '
                    'Versi Gratis dibatasi maksimal 20 produk, tanpa fitur voucher dan resep. Versi Trial memiliki akses seluruh fitur kecuali katalog resep. Paket Langganan berbayar memiliki akses penuh ke seluruh fitur tanpa batas.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinKetentuan(
                nomor: '3',
                judul: 'Kerahasiaan Akun & Keamanan',
                isi:
                    'Pengguna bertanggung jawab penuh atas keamanan kata sandi dan seluruh aktivitas transaksi yang terjadi di bawah akun toko Anda. JualinAja tidak bertanggung jawab atas kerugian akibat kelalaian menjaga kredensial.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinKetentuan(
                nomor: '4',
                judul: 'Hak Kekayaan Intelektual',
                isi:
                    'Seluruh merek, logo, ebook resep, desain antarmuka, dan sistem perangkat lunak JualinAja POS merupakan hak cipta yang dilindungi undang-undang. Penggandaan atau pendistribusian tanpa izin tertulis dilarang keras.',
              ),
              const SizedBox(height: Jarak.sm),
              const _PoinKetentuan(
                nomor: '5',
                judul: 'Perubahan Ketentuan Layanan',
                isi:
                    'Kami berhak memperbarui syarat dan ketentuan ini sewaktu-waktu demi peningkatan mutu layanan. Perubahan akan diinformasikan melalui aplikasi atau media resmi JualinAja POS.',
              ),
              const SizedBox(height: Jarak.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoinKetentuan extends StatelessWidget {
  const _PoinKetentuan({
    required this.nomor,
    required this.judul,
    required this.isi,
  });

  final String nomor;
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
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.warna.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  nomor,
                  style: TextStyle(
                    color: context.warna.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
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
