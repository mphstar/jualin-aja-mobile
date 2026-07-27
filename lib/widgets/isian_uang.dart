/// Bagian-bagian isian uang tunai.
///
/// Dipakai dua kali: saat menutup transaksi di kasir, dan saat melunasi
/// piutang. Digabung ke satu berkas karena keduanya menjawab pertanyaan yang
/// persis sama — "berapa yang diserahkan, berapa kembaliannya" — dan dua
/// salinan aturan kembalian adalah dua tempat yang cepat atau lambat menjawab
/// beda.
library;

import 'package:flutter/material.dart';

import '../data/model.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'kartu.dart';

/// Satu baris pilihan metode pembayaran.
class PilihanMetode extends StatelessWidget {
  const PilihanMetode({
    super.key,
    required this.metode,
    required this.terpilih,
    required this.onTekan,
  });

  final MetodeBayar metode;
  final bool terpilih;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: terpilih,
      child: BarisDaftar(
        awalan: Icon(
          switch (metode) {
            MetodeBayar.tunai => Icons.payments_outlined,
            MetodeBayar.qris => Icons.qr_code_2,
            MetodeBayar.transfer => Icons.account_balance_outlined,
          },
          size: 24,
          color: context.warna.onSurface,
        ),
        judul: metode.label,
        keterangan: switch (metode) {
          MetodeBayar.tunai => 'Hitung kembalian otomatis',
          MetodeBayar.qris => 'Pindai kode dari aplikasi pembeli',
          MetodeBayar.transfer => 'Konfirmasi setelah dana masuk',
        },
        bawahAkhiran: Icon(
          terpilih ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 22,
          color: terpilih
              ? context.warna.onSurface
              : context.warna.onSurfaceVariant,
        ),
        onTekan: onTekan,
      ),
    );
  }
}

/// Isian nominal plus pintasan pecahan uang.
///
/// Pintasannya dihitung dari total, bukan daftar tetap: menawarkan "Rp 50.000"
/// untuk tagihan Rp 68.000 adalah menawarkan uang yang tidak cukup.
class IsianUang extends StatelessWidget {
  const IsianUang({
    super.key,
    required this.pengendali,
    required this.total,
    required this.onUbah,
    this.fokusOtomatis = true,
  });

  final TextEditingController pengendali;
  final int total;
  final VoidCallback onUbah;

  /// Dimatikan saat isian ini bukan hal pertama yang dilihat pengguna —
  /// papan ketik yang naik sendiri menutupi kalimat yang belum sempat dibaca.
  final bool fokusOtomatis;

  /// Pecahan yang masuk akal disodorkan: uang pas, lalu pembulatan ke atas ke
  /// kelipatan yang lazim dipegang orang.
  List<int> get _pintasan {
    final hasil = <int>{total};
    for (final kelipatan in const [5000, 10000, 20000, 50000, 100000]) {
      final bulat = ((total / kelipatan).ceil()) * kelipatan;
      if (bulat > total) hasil.add(bulat);
      if (hasil.length >= 5) break;
    }
    return hasil.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: pengendali,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FormatRibuan()],
          autofocus: fokusOtomatis,
          onChanged: (_) => onUbah(),
          style: context.teks.headlineSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: const InputDecoration(prefixText: 'Rp  ', hintText: '0'),
        ),
        const SizedBox(height: Jarak.xs2),
        Wrap(
          spacing: Jarak.xs2,
          runSpacing: Jarak.xs2,
          children: [
            for (final nilai in _pintasan)
              ActionChip(
                label: Text(
                  nilai == total ? 'Uang pas' : angka(nilai),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                onPressed: () {
                  pengendali.text = angka(nilai);
                  pengendali.selection = TextSelection.collapsed(
                    offset: pengendali.text.length,
                  );
                  onUbah();
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Kembalian — atau kekurangannya, kalau uangnya belum cukup.
class BarisKembalian extends StatelessWidget {
  const BarisKembalian({
    super.key,
    required this.kembalian,
    required this.diisi,
  });

  final int kembalian;
  final bool diisi;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final kurang = kembalian < 0;
    final (latar, depan, label) = switch ((diisi, kurang)) {
      (false, _) => (a.isian, context.warna.onSurfaceVariant, 'Kembalian'),
      (true, true) => (a.bahayaLembut, a.bahaya, 'Kurang'),
      _ => (a.suksesLembut, a.sukses, 'Kembalian'),
    };

    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.teks.bodyMedium?.copyWith(
                color: depan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: Jarak.xs2),
          Flexible(
            child: Text(
              diisi ? rupiah(kembalian.abs()) : '—',
              style: context.teks.titleMedium?.copyWith(
                color: depan,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Catatan untuk metode non-tunai — tidak ada kembalian yang perlu dihitung,
/// yang perlu dipastikan justru dananya sudah benar-benar masuk.
class CatatanNonTunai extends StatelessWidget {
  const CatatanNonTunai({
    super.key,
    required this.metode,
    required this.total,
  });

  final MetodeBayar metode;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.aksen.kartuAlt,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            metode == MetodeBayar.qris
                ? Icons.qr_code_2
                : Icons.account_balance_outlined,
            size: 20,
            color: context.warna.onSurfaceVariant,
          ),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              metode == MetodeBayar.qris
                  ? 'Tunjukkan kode QRIS toko, lalu pastikan notifikasi '
                        'masuk sebesar ${rupiah(total)} sebelum menyimpan.'
                  : 'Pastikan dana ${rupiah(total)} sudah masuk ke rekening '
                        'toko sebelum menyimpan.',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris galat sebaris — dipakai di formulir yang penyimpanannya bisa gagal.
class BarisGalat extends StatelessWidget {
  const BarisGalat({super.key, required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 18, color: context.aksen.bahaya),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            pesan,
            style: context.teks.bodySmall?.copyWith(
              color: context.aksen.bahaya,
            ),
          ),
        ),
      ],
    );
  }
}
