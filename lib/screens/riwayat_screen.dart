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
import '../widgets/lembar_struk.dart';
import '../widgets/lencana.dart';
import '../widgets/rangka.dart';
import 'piutang_screen.dart';

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
        const _PintasanPiutang(),
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

/// Tautan ke daftar piutang, hanya saat memang ada yang belum tertagih.
///
/// Ditaruh di Riwayat karena di sinilah orang datang mencari struk lama — dan
/// pertanyaan "mana yang belum dibayar" hampir selalu muncul di perjalanan
/// yang sama. Saringan "Ditahan" di bawah memang menampilkan struk yang sama,
/// tapi ia menjawabnya sebagai daftar struk, bukan sebagai daftar utang: tanpa
/// jumlah total dan tanpa nama penunggak di depan.
class _PintasanPiutang extends StatelessWidget {
  const _PintasanPiutang();

  @override
  Widget build(BuildContext context) {
    return Bingkai<List<Transaksi>>(
      ambil: Repositori.piutang,
      // Rangkanya kosong, bukan petak berkedip: baris ini boleh saja tidak
      // pernah muncul, dan rangka untuk sesuatu yang mungkin tidak ada justru
      // menjanjikan isi yang tidak datang.
      rangka: const SizedBox.shrink(),
      kosong: (d) => d.isEmpty,
      saatKosong: const SizedBox.shrink(),
      isi: (context, daftar) => Padding(
        padding: const EdgeInsets.only(bottom: Jarak.xs),
        child: KartuDaftar(
          anak: [
            BarisDaftar(
              awalan: const IkonKotak(
                Icons.schedule_outlined,
                nada: NadaIkon.peringatan,
                ukuran: 36,
              ),
              judul: 'Bayar nanti',
              keterangan:
                  '${daftar.length} struk belum dibayar '
                  '${_pembeli(daftar)}',
              akhiran: rupiah(daftar.fold(0, (n, t) => n + t.total)),
              onTekan: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PiutangScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _pembeli(List<Transaksi> daftar) {
    final nama = daftar.map((t) => t.pelanggan ?? '').toSet();
    return nama.length == 1 ? '· ${nama.first}' : '· ${nama.length} pembeli';
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
    final (ikon, nada) = switch (transaksi.status) {
      StatusTransaksi.batal => (Icons.close, NadaIkon.bahaya),
      StatusTransaksi.ditahan => (Icons.schedule_outlined, NadaIkon.peringatan),
      StatusTransaksi.selesai => (Icons.check, NadaIkon.sukses),
    };

    return BarisDaftar(
      awalan: IkonKotak(ikon, nada: nada, ukuran: 36),
      judul: transaksi.nomorStruk,
      keterangan: transaksi.piutang
          // Untuk piutang, metode pembayaran belum berarti apa-apa — yang
          // dicari mata di baris ini adalah siapa yang berutang.
          ? '${jam(transaksi.waktu)} · ${transaksi.pelanggan ?? 'Tanpa nama'}'
          : '${jam(transaksi.waktu)} · ${transaksi.metode.label} · '
                '${transaksi.jumlahItem} item',
      akhiran: rupiah(transaksi.total),
      bawahAkhiran: batal || transaksi.piutang
          ? Lencana.transaksi(transaksi.status)
          : null,
      onTekan: () => LembarStruk.tampilkan(context, transaksi),
    );
  }
}
