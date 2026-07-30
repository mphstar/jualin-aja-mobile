import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../screens/sunting_pesanan_screen.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../util/pencetak_struk.dart';
import 'kartu.dart';
import 'lembar_pelunasan.dart';
import 'lencana.dart';

/// Apa yang diminta pengguna dari lembar struk.
///
/// Dikembalikan lewat `pop`, bukan dikerjakan di dalam lembarnya: kedua aksi
/// membuka permukaan baru, dan permukaan yang tumbuh di atas lembar bawah
/// menyisakan tepi lembar pertama yang mengambang dan tidak bisa disentuh.
enum _AksiStruk { bayar, ubah }

/// Detail satu struk sebagai lembar bawah.
///
/// Rinciannya nyata — barisnya diambil dari transaksi, bukan diringkas ulang.
/// Satu bentuk dipakai di Beranda, Riwayat, dan daftar piutang: struk yang
/// tampil berbeda tergantung dari mana ia dibuka adalah struk yang membuat
/// orang ragu apakah keduanya benar-benar transaksi yang sama.
class LembarStruk extends StatelessWidget {
  const LembarStruk({super.key, required this.transaksi});

  final Transaksi transaksi;

  /// Buka lembarnya, lalu lanjutkan ke permukaan yang diminta: lembar
  /// pelunasan, atau layar ubah pesanan.
  ///
  /// Lembarnya ditutup lebih dulu, tidak ditumpuk.
  static Future<void> tampilkan(
    BuildContext context,
    Transaksi transaksi,
  ) async {
    final aksi = await showModalBottomSheet<_AksiStruk>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => LembarStruk(transaksi: transaksi),
    );
    if (aksi == null || !context.mounted) return;

    switch (aksi) {
      case _AksiStruk.ubah:
        final tersimpan = await SuntingPesananScreen.tampilkan(
          context,
          transaksi,
        );
        if (!tersimpan || !context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Pesanan ${transaksi.nomorStruk} diperbarui'),
            ),
          );

      case _AksiStruk.bayar:
        final lunas = await tampilkanLembarPelunasan(context, transaksi);
        if (!lunas || !context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Piutang ${transaksi.pelanggan ?? transaksi.nomorStruk} lunas · '
                '${rupiah(transaksi.total)}',
              ),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transaksi.nomorStruk,
                    style: context.teks.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Jarak.xs2),
                Lencana.transaksi(transaksi.status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${tanggal(transaksi.waktu)} · ${jam(transaksi.waktu)} · '
              '${transaksi.metode.label}',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
            ),
            if (transaksi.piutang && transaksi.pelanggan != null) ...[
              const SizedBox(height: Jarak.xs),
              PanelPiutang(
                nama: transaksi.pelanggan!,
                total: transaksi.total,
                sejak: transaksi.waktu,
              ),
            ],
            const SizedBox(height: Jarak.sm),
            KartuDaftar(
              anak: [
                for (final b in transaksi.baris)
                  BarisDaftar(
                    awalan: SizedBox(
                      width: 28,
                      child: Text(
                        '${b.jumlah}×',
                        style: context.teks.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.warna.onSurfaceVariant,
                        ),
                      ),
                    ),
                    judul: b.nama,
                    keterangan: rupiah(b.hargaSatuan),
                    akhiran: rupiah(b.subtotal),
                  ),
              ],
            ),
            if (transaksi.adaDiskon) ...[
              _BarisRingan(
                label: 'Subtotal',
                nilai: rupiah(transaksi.subtotal),
              ),
              _BarisRingan(
                label: transaksi.diskonTipe == 'PERSEN'
                    ? 'Diskon (${transaksi.diskonNilai}%)'
                    : 'Diskon Rp',
                nilai: '-${rupiah(transaksi.diskonNominal)}',
              ),
              const SizedBox(height: Jarak.xs3),
            ],
            Row(
              children: [
                Expanded(child: Text('Total', style: context.teks.titleMedium)),
                Flexible(
                  child: Text(
                    rupiah(transaksi.total),
                    style: context.teks.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (transaksi.kembalian case final kembalian?
                when !transaksi.piutang) ...[
              const SizedBox(height: Jarak.xs3),
              _BarisRingan(
                label: 'Tunai ${rupiah(transaksi.uangDiterima!)}',
                nilai: 'Kembali ${rupiah(kembalian)}',
              ),
            ],
            const SizedBox(height: Jarak.sm),
            if (transaksi.piutang) ...[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_AksiStruk.bayar),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Terima pembayaran'),
              ),
              const SizedBox(height: Jarak.xs2),
              // Hanya muncul selama utangnya belum lunas. Struk yang sudah
              // dibayar tidak boleh berubah isinya: uangnya sudah diterima,
              // angkanya sudah masuk laporan, dan kertasnya sudah di tangan
              // pembeli.
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(_AksiStruk.ubah),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Ubah pesanan'),
              ),
              const SizedBox(height: Jarak.xs2),
              Text(
                'Selama belum dilunasi, barangnya masih bisa ditambah, '
                'dikurangi, atau dihapus — stok ikut menyesuaikan.',
                textAlign: TextAlign.center,
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cetak(context),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Cetak ulang'),
                    ),
                  ),
                  const SizedBox(width: Jarak.xs2),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _bagikan(context),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Bagikan'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _cetak(BuildContext context) async {
    final pesan = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      final toko = await Repositori.toko();
      final pengaturan = await Repositori.pengaturanStruk();
      if (!context.mounted) return;
      await PencetakStruk.cetakOtomatisBluetooth(
        context,
        toko: toko,
        pengaturan: pengaturan,
        transaksi: transaksi,
      );
    } catch (e) {
      pesan.showSnackBar(
        SnackBar(content: Text('Gagal mencetak struk: $e')),
      );
    }
  }

  Future<void> _bagikan(BuildContext context) async {
    final pesan = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      final toko = await Repositori.toko();
      final pengaturan = await Repositori.pengaturanStruk();
      if (!context.mounted) return;
      await PencetakStruk.bagikanStruk(
        context,
        toko: toko,
        pengaturan: pengaturan,
        transaksi: transaksi,
      );
    } catch (e) {
      pesan.showSnackBar(
        SnackBar(content: Text('Gagal membagikan struk: $e')),
      );
    }
  }
}

/// Sorotan piutang di dalam detail struk.
///
/// Nama penghutang ditaruh di sini, bukan diselipkan ke baris tanggal: ia
/// satu-satunya keterangan yang menentukan apakah utang ini bisa ditagih.
class PanelPiutang extends StatelessWidget {
  const PanelPiutang({
    super.key,
    required this.nama,
    required this.total,
    required this.sejak,
  });

  final String nama;
  final int total;
  final DateTime sejak;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: a.peringatanLembut,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined, size: 20, color: a.peringatan),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              '$nama belum membayar ${rupiah(total)} — ${relatif(sejak)}.',
              style: context.teks.bodySmall?.copyWith(
                color: a.peringatan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris keterangan kecil di bawah total: uang yang diserahkan dan
/// kembaliannya. Redup, karena ia catatan — bukan angka yang dicari.
class _BarisRingan extends StatelessWidget {
  const _BarisRingan({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    final gaya = context.teks.bodySmall?.copyWith(
      color: context.warna.onSurfaceVariant,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: gaya)),
        const SizedBox(width: Jarak.xs2),
        Text(nilai, style: gaya),
      ],
    );
  }
}
