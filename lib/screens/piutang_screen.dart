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
import '../widgets/rangka.dart';

/// Daftar piutang — semua transaksi "bayar nanti" yang belum dilunasi.
///
/// Alasan halaman ini ada terpisah dari Riwayat: Riwayat menjawab "apa yang
/// terjadi", piutang menjawab **"siapa yang masih berutang berapa"**. Kedua
/// pertanyaan itu memang bisa dijawab dari data yang sama, tapi jawaban kedua
/// menuntut pengelompokan per orang dan urutan menurut lamanya menunggak —
/// dan menyaring Riwayat ke "Ditahan" tidak memberi keduanya.
///
/// Yang paling lama menunggak berada di atas. Utang warung tidak ditagih
/// menurut besarnya, melainkan menurut umurnya: yang sudah dua minggu lewat
/// adalah yang paling mungkin tidak pernah kembali.
class PiutangScreen extends StatelessWidget {
  const PiutangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bayar nanti')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Bingkai<List<Transaksi>>(
              ambil: Repositori.piutang,
              rangka: const Padding(
                padding: EdgeInsets.all(Jarak.sm),
                child: Column(
                  children: [
                    RangkaPanel(tinggi: 104),
                    SizedBox(height: Jarak.md),
                    RangkaDaftar(baris: 4),
                  ],
                ),
              ),
              kosong: (d) => d.isEmpty,
              saatKosong: const Padding(
                padding: EdgeInsets.all(Jarak.sm),
                child: Keadaan(
                  ikon: Icons.verified_outlined,
                  judul: 'Tidak ada piutang',
                  keterangan:
                      'Semua transaksi sudah dibayar. Yang ditutup dengan '
                      '"Bayar nanti" di kasir akan menunggu di sini sampai '
                      'dilunasi.',
                ),
              ),
              isi: (context, daftar) => _Isi(daftar: daftar),
            ),
          ),
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.daftar});

  final List<Transaksi> daftar;

  /// Piutang tanpa nama seharusnya tidak pernah tercipta — lembar "Bayar
  /// nanti" mewajibkannya. Tapi data lama bisa saja punya, dan membuangnya
  /// diam-diam berarti menghilangkan uang dari total tanpa jejak.
  static const _tanpaNama = 'Tanpa nama';

  @override
  Widget build(BuildContext context) {
    final total = daftar.fold(0, (n, t) => n + t.total);

    final perOrang = <String, List<Transaksi>>{};
    for (final t in daftar) {
      final nama = (t.pelanggan ?? '').trim();
      perOrang
          .putIfAbsent(nama.isEmpty ? _tanpaNama : nama, () => [])
          .add(t);
    }
    for (final struk in perOrang.values) {
      struk.sort((a, b) => a.waktu.compareTo(b.waktu));
    }

    final grup = perOrang.entries.toList()
      ..sort((a, b) => a.value.first.waktu.compareTo(b.value.first.waktu));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Jarak.sm,
        Jarak.xs,
        Jarak.sm,
        Jarak.sm,
      ),
      children: [
        PanelAngka(
          label: 'Belum tertagih',
          nilai: rupiah(total),
          keterangan:
              '${daftar.length} struk · ${perOrang.length} pembeli · '
              'tertua ${relatif(grup.first.value.first.waktu)}',
        ),
        const SizedBox(height: Jarak.xs),
        const _Catatan(),
        const SizedBox(height: Jarak.md),

        for (final e in grup) ...[
          JudulBagian(
            e.key,
            aksi: Text(
              rupiah(e.value.fold(0, (n, t) => n + t.total)),
              style: context.teks.labelSmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ),
          KartuDaftar(
            anak: [for (final t in e.value) _BarisPiutang(transaksi: t)],
          ),
          const SizedBox(height: Jarak.md),
        ],
      ],
    );
  }
}

class _BarisPiutang extends StatelessWidget {
  const _BarisPiutang({required this.transaksi});

  final Transaksi transaksi;

  /// Utang yang sudah lewat sepekan naik nadanya jadi merah.
  ///
  /// Ambangnya bukan angka bulat yang dikarang: sepekan adalah jarak paling
  /// lama antara dua kunjungan pelanggan tetap warung. Lewat dari itu, orangnya
  /// sudah tidak datang — dan menagih perlu usaha, bukan menunggu.
  bool get _lewatTempo =>
      DateTime.now().difference(transaksi.waktu).inDays >= 7;

  @override
  Widget build(BuildContext context) {
    return BarisDaftar(
      awalan: IkonKotak(
        _lewatTempo ? Icons.priority_high : Icons.schedule_outlined,
        nada: _lewatTempo ? NadaIkon.bahaya : NadaIkon.peringatan,
        ukuran: 36,
      ),
      judul: transaksi.nomorStruk,
      keterangan:
          '${relatif(transaksi.waktu)} · ${transaksi.jumlahItem} item',
      warnaKeterangan: _lewatTempo ? context.aksen.bahaya : null,
      akhiran: rupiah(transaksi.total),
      onTekan: () => LembarStruk.tampilkan(context, transaksi),
    );
  }
}

/// Pengingat kenapa angka di panel atas tidak muncul di Laporan.
///
/// Tanpa kalimat ini, pemilik toko yang melihat "Rp 180.000 belum tertagih"
/// akan mencarinya di omzet dan mengira laporannya kurang.
class _Catatan extends StatelessWidget {
  const _Catatan();

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
            Icons.info_outline,
            size: 20,
            color: context.warna.onSurfaceVariant,
          ),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              'Barangnya sudah keluar dan stok sudah berkurang, tapi angka ini '
              'belum masuk omzet di Laporan. Ia baru ikut dihitung setelah '
              'dilunasi — di tanggal transaksinya, bukan tanggal pelunasan.',
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
