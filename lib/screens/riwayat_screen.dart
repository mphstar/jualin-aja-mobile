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
import '../widgets/lencana.dart';
import '../widgets/rangka.dart';

/// Riwayat transaksi — tab kedua di dalam Laporan.
///
/// Bukan tujuan navigasi tersendiri, karena ia dan Ringkasan adalah **data
/// yang sama pada dua tingkat perbesaran**: satu menjawab "bagaimana minggu
/// ini", satu menjawab "mana struk yang tadi". Memisahkannya jadi dua tab nav
/// memaksa pengguna memilih lebih dulu pertanyaan mana yang sedang ia punya.
///
/// Penyaringan dikerjakan di [Repositori], bukan di sini — supaya saat pindah
/// ke sisi server nanti, layarnya tidak ikut diubah.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, required this.padding});

  final EdgeInsets padding;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _kendaliCari = TextEditingController();
  String _cari = '';
  StatusTransaksi? _status;

  @override
  void dispose() {
    _kendaliCari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.padding;
    return ListView(
      padding: EdgeInsets.fromLTRB(p.left, Jarak.sm, p.right, p.bottom),
      children: [
        TextField(
          controller: _kendaliCari,
          onChanged: (v) => setState(() => _cari = v),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cari nomor struk atau produk',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _cari.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _kendaliCari.clear();
                      setState(() => _cari = '');
                    },
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Hapus pencarian',
                  ),
          ),
        ),
        const SizedBox(height: Jarak.xs),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Saring(
                label: 'Semua',
                aktif: _status == null,
                onTekan: () => setState(() => _status = null),
              ),
              for (final s in StatusTransaksi.values)
                _Saring(
                  label: switch (s) {
                    StatusTransaksi.selesai => 'Selesai',
                    StatusTransaksi.ditahan => 'Ditahan',
                    StatusTransaksi.batal => 'Batal',
                  },
                  aktif: _status == s,
                  onTekan: () => setState(() => _status = s),
                ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.sm),
        Bingkai<List<Transaksi>>(
          // Kunci ikut nilai saringan, jadi setiap perubahan saringan memicu
          // pengambilan ulang lengkap dengan rangka pemuatannya — bukan diam
          // beberapa ratus milidetik lalu isinya berganti tiba-tiba.
          key: ValueKey('$_cari|$_status'),
          ambil: () => Repositori.riwayat(cari: _cari, status: _status),
          rangka: const RangkaDaftar(baris: 6),
          kosong: (d) => d.isEmpty,
          saatKosong: Keadaan(
            ikon: Icons.receipt_long_outlined,
            judul: _cari.isEmpty && _status == null
                ? 'Belum ada transaksi'
                : 'Tidak ada yang cocok',
            keterangan: _cari.isEmpty && _status == null
                ? 'Transaksi pertama akan muncul di sini begitu Anda '
                      'menutup satu pesanan di kasir.'
                : 'Coba kata kunci lain, atau kembalikan saringan ke '
                      '"Semua".',
            labelAksi: _cari.isEmpty && _status == null ? null : 'Atur ulang',
            onAksi: _cari.isEmpty && _status == null
                ? null
                : () {
                    _kendaliCari.clear();
                    setState(() {
                      _cari = '';
                      _status = null;
                    });
                  },
          ),
          isi: (context, daftar) => _DaftarBerhari(daftar: daftar),
        ),
      ],
    );
  }
}

class _Saring extends StatelessWidget {
  const _Saring({
    required this.label,
    required this.aktif,
    required this.onTekan,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Jarak.xs2),
      child: Semantics(
        button: true,
        selected: aktif,
        child: InkWell(
          onTap: onTekan,
          borderRadius: BorderRadius.circular(Lengkung.bulat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Jarak.xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: aktif
                  ? context.aksen.fokus
                  : context.warna.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(Lengkung.bulat),
              border: Border.all(
                color: aktif ? context.aksen.fokus : context.warna.outline,
              ),
            ),
            child: Text(
              label,
              style: context.teks.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: aktif
                    ? context.aksen.atasFokus
                    : context.warna.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Daftar berkelompok per hari, dengan subtotal per kelompok.
///
/// Subtotal harian itu yang membedakan riwayat dari sekadar log: tanpa itu,
/// pertanyaan "kemarin dapat berapa" hanya bisa dijawab dengan menjumlah
/// sendiri di kepala.
class _DaftarBerhari extends StatelessWidget {
  const _DaftarBerhari({required this.daftar});

  final List<Transaksi> daftar;

  @override
  Widget build(BuildContext context) {
    final perHari = <DateTime, List<Transaksi>>{};
    for (final t in daftar) {
      final hari = DateTime(t.waktu.year, t.waktu.month, t.waktu.day);
      perHari.putIfAbsent(hari, () => []).add(t);
    }

    final kini = DateTime.now();
    final hariIni = DateTime(kini.year, kini.month, kini.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in perHari.entries) ...[
          JudulBagian(
            e.key == hariIni
                ? 'Hari ini'
                : e.key == hariIni.subtract(const Duration(days: 1))
                ? 'Kemarin'
                : tanggal(e.key),
            aksi: Text(
              rupiah(
                e.value.where((t) => t.dihitung).fold(0, (n, t) => n + t.total),
              ),
              style: context.teks.labelSmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ),
          KartuDaftar(
            anak: [for (final t in e.value) _BarisTransaksi(transaksi: t)],
          ),
          const SizedBox(height: Jarak.md),
        ],
      ],
    );
  }
}

class _BarisTransaksi extends StatelessWidget {
  const _BarisTransaksi({required this.transaksi});

  final Transaksi transaksi;

  @override
  Widget build(BuildContext context) {
    final batal = transaksi.status == StatusTransaksi.batal;
    return BarisDaftar(
      awalan: IkonKotak(
        batal ? Icons.close : Icons.check,
        nada: batal ? NadaIkon.bahaya : NadaIkon.sukses,
        ukuran: 36,
      ),
      judul: transaksi.nomorStruk,
      keterangan:
          '${jam(transaksi.waktu)} · ${transaksi.metode.label} · '
          '${transaksi.jumlahItem} item',
      akhiran: rupiah(transaksi.total),
      bawahAkhiran: batal ? Lencana.transaksi(transaksi.status) : null,
      onTekan: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _DetailStruk(transaksi: transaksi),
      ),
    );
  }
}

/// Detail struk. Rincinya nyata — barisnya diambil dari transaksi, bukan
/// diringkas ulang.
class _DetailStruk extends StatelessWidget {
  const _DetailStruk({required this.transaksi});

  final Transaksi transaksi;

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
            const SizedBox(height: Jarak.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Cetak struk menyusul.')),
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
