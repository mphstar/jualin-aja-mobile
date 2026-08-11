import 'package:flutter/material.dart';

import '../screens/perpanjang_screen.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'tombol_pil.dart';

/// Jenis fitur yang sedang terkunci dan memerlukan upgrade paket.
enum JenisFiturTerkunci {
  resep,
  voucher,
  batasProduk,
  kakiStruk,
}

/// Bottom sheet interaktif dan atraktif untuk memotivasi pengguna melakukan upgrade langganan.
class ModalFiturTerkunci extends StatelessWidget {
  const ModalFiturTerkunci({
    super.key,
    required this.jenis,
  });

  final JenisFiturTerkunci jenis;

  /// Membuka lembar modal fitur terkunci.
  static Future<void> tampilkan(
    BuildContext context, {
    required JenisFiturTerkunci jenis,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalFiturTerkunci(jenis: jenis),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (judul, subjudul, ikon, poinBenefit) = _isiContent();

    return Container(
      decoration: BoxDecoration(
        color: context.warna.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Lengkung.panel),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Jarak.md,
        Jarak.sm,
        Jarak.md,
        MediaQuery.of(context).padding.bottom + Jarak.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bilah pegangan atas
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.warna.onSurfaceVariant.withAlpha(76),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Jarak.md),

          // Spanduk Utama dengan Aksen Visual Premium & Glow
          Container(
            padding: const EdgeInsets.all(Jarak.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.warna.primaryContainer,
                  context.warna.surfaceContainerHigh,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Lengkung.kontrol),
              border: Border.all(
                color: context.warna.primary.withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: context.warna.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.warna.primary.withAlpha(90),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    ikon,
                    color: context.warna.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: Jarak.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: Jarak.xs3),
                      Text(
                        subjudul,
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Jarak.md),

          // Judul Seksi Keunggulan
          Row(
            children: [
              Icon(
                Icons.stars_rounded,
                size: 20,
                color: context.warna.primary,
              ),
              const SizedBox(width: Jarak.xs2),
              Text(
                'Keunggulan Upgrade Paket:',
                style: context.teks.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.xs),

          // Daftar Poin Benefit
          ...poinBenefit.map(
            (poin) => Padding(
              padding: const EdgeInsets.only(bottom: Jarak.xs2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: context.warna.primary,
                    ),
                  ),
                  const SizedBox(width: Jarak.xs2),
                  Expanded(
                    child: Text(
                      poin,
                      style: context.teks.bodyMedium?.copyWith(
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Jarak.md),

          // Tombol Utama Ke Pembelian Langganan
          TombolPil(
            label: 'Tingkatkan Paket Sekarang',
            onTekan: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PerpanjangScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: Jarak.xs2),

          // Tombol Batal/Nanti Saja
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Nanti Saja',
                style: TextStyle(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, String, IconData, List<String>) _isiContent() {
    switch (jenis) {
      case JenisFiturTerkunci.resep:
        return (
          'Buka 100+ Resep Rahasia',
          'Tersedia eksklusif untuk pengguna paket Langganan aktif.',
          Icons.menu_book_rounded,
          [
            'Akses 100+ Ebook resep makanan & minuman siap jual',
            'Lengkap dengan takaran bahan presisi & estimasi HPP',
            'Update resep baru tanpa biaya tambahan',
          ],
        );
      case JenisFiturTerkunci.voucher:
        return (
          'Buka Fitur Diskon & Voucher',
          'Tersedia untuk pengguna paket Trial & Langganan.',
          Icons.confirmation_number_rounded,
          [
            'Buat potongan harga persentase atau nominal tunai',
            'Tingkatkan transaksi & daya tarik promosi toko',
            'Otomatis terhitung di struk kasir saat checkout',
          ],
        );
      case JenisFiturTerkunci.batasProduk:
        return (
          'Buka Batas Maksimal Produk',
          'Akun Gratis dibatasi 5 produk. Upgrade untuk produk tanpa batas.',
          Icons.inventory_2_rounded,
          [
            'Tambah produk & varian tanpa batas jumlah',
            'Kelola stok barang otomatis & peringatan stok habis',
            'Fitur impor & ekspor katalog lewat berkas Excel',
          ],
        );
      case JenisFiturTerkunci.kakiStruk:
        return (
          'Kustomisasi Teks Kaki Struk',
          'Teks bawaan "Copyright by JualinAja". Upgrade ke Pro untuk kustomisasi!',
          Icons.receipt_long_rounded,
          [
            'Ubah teks kaki (footer) struk sesuai branding toko Anda',
            'Sampaikan ucapan terima kasih, pesan khusus, atau akun medsos toko',
            'Bebas ubah kapan saja untuk cetak Bluetooth & PDF struk',
          ],
        );
    }
  }
}
