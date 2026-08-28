import 'package:flutter/material.dart';

import '../screens/perpanjang_screen.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'ikon_kotak.dart';
import 'tombol_pil.dart';

/// Jenis fitur yang sedang terkunci dan memerlukan upgrade paket.
enum JenisFiturTerkunci {
  resep,
  voucher,
  batasProduk,
  kakiStruk,
}

/// Dialog fitur terkunci — lembar bawah yang jujur dan tenang, lalu mengarahkan
/// ke halaman pembayaran langganan (`PerpanjangScreen`).
///
/// Mengikuti `design.md`: permukaan datar, tanpa gradien/bayangan; kroma hanya
/// untuk aksi utama. Perannya bukan menjual dengan hiasan, tapi menjawab satu
/// pertanyaan: "fitur ini butuh apa, dan bagaimana saya mendapatkannya?".
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
    final (judul, keterangan, ikon, poinBenefit) = _isiContent();

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
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.warna.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Jarak.md),
          Row(
            children: [
              IkonKotak(ikon, nada: NadaIkon.tinta, ukuran: 44),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: context.teks.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs3),
                    Text(
                      keterangan,
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.md),
          for (final poin in poinBenefit)
            Padding(
              padding: const EdgeInsets.only(bottom: Jarak.xs2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: context.warna.onSurfaceVariant,
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
          const SizedBox(height: Jarak.md),
          TombolPil(
            label: 'Tingkatkan Paket',
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
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Nanti saja',
                style: TextStyle(color: context.warna.onSurfaceVariant),
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
          'Buka Pustaka Resep',
          'Resep dan prompt hanya untuk paket Langganan aktif.',
          Icons.auto_stories_rounded,
          [
            'Akses ebook resep & prompt siap pakai',
            'Takaran bahan presisi dan estimasi HPP',
            'Konten baru tanpa biaya tambahan',
          ],
        );
      case JenisFiturTerkunci.voucher:
        return (
          'Buka Diskon & Voucher',
          'Fitur diskon untuk paket Trial & Langganan.',
          Icons.confirmation_number_rounded,
          [
            'Potongan harga persentase atau nominal',
            'Dorong transaksi dan promosi toko',
            'Otomatis terhitung di struk kasir',
          ],
        );
      case JenisFiturTerkunci.batasProduk:
        return (
          'Buka Produk Tanpa Batas',
          'Akun Gratis dibatasi 5 produk. Upgrade untuk tanpa batas.',
          Icons.inventory_2_rounded,
          [
            'Tambah produk & varian tanpa batas',
            'Kelola stok dan peringatan stok habis',
            'Impor & ekspor katalog via Excel',
          ],
        );
      case JenisFiturTerkunci.kakiStruk:
        return (
          'Kustomisasi Kaki Struk',
          'Teks bawaan "Copyright by JualinAja". Upgrade untuk mengubahnya.',
          Icons.receipt_long_rounded,
          [
            'Ubah teks kaki struk sesuai branding toko',
            'Ucapan terima kasih, pesan, atau akun medsos',
            'Bebas ubah untuk cetak Bluetooth & PDF struk',
          ],
        );
    }
  }
}
