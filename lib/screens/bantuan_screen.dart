import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/ikon_kotak.dart';
import '../widgets/kartu.dart';
import '../util/tautan_wa.dart';
import 'tiket_screen.dart';

/// Halaman Bantuan dan Dukungan Pelanggan (FAQ & Contact Support).
class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bantuan & Dukungan'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Jarak.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seksi Kontak Dukungan
              Text('Hubungi Kami', style: context.teks.titleMedium),
              const SizedBox(height: Jarak.xs),
              KartuDaftar(
                anak: [
                  BarisDaftar(
                    awalan: const IkonKotak(Icons.rate_review_outlined, ukuran: 36),
                    judul: 'Saran & Komplain',
                    keterangan: 'Kirim masukan atau laporkan kendala ke admin',
                    bawahAkhiran: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: context.warna.onSurfaceVariant,
                    ),
                    onTekan: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TiketScreen(),
                      ),
                    ),
                  ),
                  BarisDaftar(
                    awalan: const IkonKotak(Icons.chat_bubble_outline, ukuran: 36),
                    judul: 'WhatsApp CS Support',
                    keterangan: '+$nomorWhatsAppCSDefault (Respon Cepat)',
                    bawahAkhiran: Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: context.warna.onSurfaceVariant,
                    ),
                    onTekan: () => bukaWhatsApp(context),
                  ),
                  BarisDaftar(
                    awalan: const IkonKotak(Icons.mail_outline, ukuran: 36),
                    judul: 'Email Support',
                    keterangan: 'support@jualinaja.id',
                    bawahAkhiran: Icon(
                      Icons.copy,
                      size: 18,
                      color: context.warna.onSurfaceVariant,
                    ),
                    onTekan: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Alamat email support@jualinaja.id berhasil disalin'),
                          ),
                        );
                    },
                  ),
                  BarisDaftar(
                    awalan: const IkonKotak(Icons.access_time_outlined, ukuran: 36),
                    judul: 'Jam Operasional CS',
                    keterangan: 'Senin – Minggu (08.00 – 21.00 WIB)',
                  ),
                ],
              ),
              const SizedBox(height: Jarak.md),

              // Seksi FAQ
              Text('Pertanyaan Sering Diajukan (FAQ)', style: context.teks.titleMedium),
              const SizedBox(height: Jarak.xs),
              const _KartuFaq(
                pertanyaan: 'Bagaimana cara menambah produk baru?',
                jawaban:
                    'Buka menu Produk melalui bilah navigasi bawah, lalu tekan tombol "Tambah Produk". '
                    'Isi nama, kategori, harga jual, dan stok awal lalu tekan Simpan.',
              ),
              const SizedBox(height: Jarak.xs2),
              const _KartuFaq(
                pertanyaan: 'Bagaimana cara mencetak struk transaksi?',
                jawaban:
                    'Buka menu Akun > Struk & Printer untuk menghubungkan printer Bluetooth Thermal Anda. '
                    'Struk akan otomatis dapat dicetak setelah setiap kali transaksi selesai di kasir.',
              ),
              const SizedBox(height: Jarak.xs2),
              const _KartuFaq(
                pertanyaan: 'Bagaimana cara perpanjang paket langganan?',
                jawaban:
                    'Masuk ke menu Akun, tekan tombol "Perpanjang langganan" pada kartu status di bagian atas, '
                    'pilih durasi paket (Bulanan / Semesteran / Tahunan) dan lakukan pembayaran.',
              ),
              const SizedBox(height: Jarak.xs2),
              const _KartuFaq(
                pertanyaan: 'Bagaimana jika stok produk tidak sesuai?',
                jawaban:
                    'Anda dapat memperbarui stok secara manual kapan saja dari menu Produk dengan memilih produk '
                    'yang bersangkutan lalu mengubah angka stoknya.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuFaq extends StatefulWidget {
  const _KartuFaq({
    required this.pertanyaan,
    required this.jawaban,
  });

  final String pertanyaan;
  final String jawaban;

  @override
  State<_KartuFaq> createState() => _KartuFaqState();
}

class _KartuFaqState extends State<_KartuFaq> {
  bool _terbuka = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (v) => setState(() => _terbuka = v),
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: Jarak.sm,
          vertical: Jarak.xs2,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          Jarak.sm,
          0,
          Jarak.sm,
          Jarak.sm,
        ),
        title: Text(
          widget.pertanyaan,
          style: context.teks.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          _terbuka ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: context.warna.onSurfaceVariant,
        ),
        children: [
          Text(
            widget.jawaban,
            style: context.teks.bodyMedium?.copyWith(
              color: context.warna.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
