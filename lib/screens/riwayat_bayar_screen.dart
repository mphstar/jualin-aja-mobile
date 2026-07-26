import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/bingkai.dart';
import '../widgets/ikon_kotak.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/rangka.dart';
import 'status_bayar_screen.dart';

/// Riwayat tagihan langganan (PRD M6).
///
/// Sisi mobile dari catatan yang sama yang dilihat admin di panel web. Tagihan
/// yang masih menunggu bisa dibuka lagi — itu inti gunanya layar ini: orang
/// yang menutup aplikasi di tengah pembayaran butuh jalan kembali ke nomor VA
/// yang sudah terlanjur dibuat, bukan tagihan baru.
class RiwayatBayarScreen extends StatelessWidget {
  const RiwayatBayarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
        ),
        title: const Text('Riwayat pembayaran'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Bingkai<List<Tagihan>>(
              ambil: Repositori.riwayatTagihan,
              rangka: const Padding(
                padding: EdgeInsets.all(Jarak.sm),
                child: RangkaDaftar(baris: 4),
              ),
              kosong: (d) => d.isEmpty,
              saatKosong: const Padding(
                padding: EdgeInsets.all(Jarak.sm),
                child: Keadaan(
                  ikon: Icons.receipt_long_outlined,
                  judul: 'Belum ada pembayaran',
                  keterangan:
                      'Tagihan langganan akan tercatat di sini begitu Anda '
                      'melakukan perpanjangan pertama.',
                ),
              ),
              isi: (context, daftar) => ListView(
                padding: const EdgeInsets.all(Jarak.sm),
                children: [
                  _Ringkas(daftar: daftar),
                  const SizedBox(height: Jarak.md),
                  const JudulBagian('Semua tagihan'),
                  KartuDaftar(
                    anak: [for (final t in daftar) _BarisTagihan(tagihan: t)],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ringkas extends StatelessWidget {
  const _Ringkas({required this.daftar});

  final List<Tagihan> daftar;

  @override
  Widget build(BuildContext context) {
    final lunas = daftar.where((t) => t.statusKini == StatusBayar.lunas);
    final menunggu = daftar
        .where((t) => t.statusKini == StatusBayar.menunggu)
        .length;
    final total = lunas.fold(0, (n, t) => n + t.nominal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Jarak.sm,
          vertical: Jarak.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: _Angka(label: 'Total dibayar', nilai: rupiah(total)),
            ),
            Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
              color: context.warna.outline,
            ),
            Expanded(
              child: _Angka(
                label: 'Menunggu',
                nilai: '$menunggu',
                warna: menunggu > 0 ? context.aksen.peringatan : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka({required this.label, required this.nilai, this.warna});

  final String label;
  final String nilai;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            nilai,
            style: context.teks.titleLarge?.copyWith(
              color: warna,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(
          label,
          style: context.teks.bodySmall?.copyWith(
            color: context.warna.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BarisTagihan extends StatelessWidget {
  const _BarisTagihan({required this.tagihan});

  final Tagihan tagihan;

  @override
  Widget build(BuildContext context) {
    final status = tagihan.statusKini;
    final nada = switch (status) {
      StatusBayar.lunas => NadaIkon.sukses,
      StatusBayar.menunggu => NadaIkon.peringatan,
      StatusBayar.gagal => NadaIkon.bahaya,
      StatusBayar.kedaluwarsa => NadaIkon.netral,
    };
    final ikon = switch (status) {
      StatusBayar.lunas => Icons.check,
      StatusBayar.menunggu => Icons.schedule,
      StatusBayar.gagal => Icons.close,
      StatusBayar.kedaluwarsa => Icons.timer_off_outlined,
    };

    return BarisDaftar(
      awalan: IkonKotak(ikon, nada: nada, ukuran: 36),
      judul: tagihan.nomorInvoice,
      keterangan:
          '${tanggal(tagihan.dibuat)} · ${tagihan.durasi.label} · '
          '${tagihan.saluran.label}',
      akhiran: rupiah(tagihan.nominal),
      bawahAkhiran: LencanaBayar(status: status),
      // Hanya yang masih menunggu yang bisa dibuka lagi — tagihan lunas tidak
      // punya apa pun untuk dikerjakan, dan membukanya cuma jalan buntu.
      onTekan: status == StatusBayar.menunggu
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StatusBayarScreen(tagihan: tagihan),
              ),
            )
          : null,
    );
  }
}
