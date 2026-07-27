import 'package:flutter/material.dart';

import '../data/model.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'kartu.dart';
import 'lembar_pelunasan.dart';
import 'lencana.dart';

/// Detail satu struk sebagai lembar bawah.
///
/// Rinciannya nyata — barisnya diambil dari transaksi, bukan diringkas ulang.
/// Satu bentuk dipakai di Beranda, Riwayat, dan daftar piutang: struk yang
/// tampil berbeda tergantung dari mana ia dibuka adalah struk yang membuat
/// orang ragu apakah keduanya benar-benar transaksi yang sama.
class LembarStruk extends StatelessWidget {
  const LembarStruk({super.key, required this.transaksi});

  final Transaksi transaksi;

  /// Buka lembarnya, lalu — kalau pengguna menekan "Terima pembayaran" —
  /// lanjutkan ke lembar pelunasan.
  ///
  /// Kedua lembar sengaja tidak ditumpuk: lembar bawah di atas lembar bawah
  /// menyisakan tepi lembar pertama yang mengambang dan tidak bisa disentuh.
  /// Yang pertama ditutup dulu, yang kedua menggantikannya.
  static Future<void> tampilkan(
    BuildContext context,
    Transaksi transaksi,
  ) async {
    final mintaBayar = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => LembarStruk(transaksi: transaksi),
    );
    if (mintaBayar != true || !context.mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
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
            const SizedBox(height: Jarak.xs),
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
            if (transaksi.piutang)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Terima pembayaran'),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  final pesan = ScaffoldMessenger.of(context);
                  Navigator.of(context).pop();
                  pesan
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Printer belum tersambung. '
                          'Atur di Akun · Struk & printer.',
                        ),
                      ),
                    );
                },
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Cetak ulang'),
              ),
          ],
        ),
      ),
    );
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
