import 'package:flutter/material.dart';

import '../data/contoh.dart';
import '../data/model.dart';
import '../data/repositori.dart';
import '../data/sesi_kasir.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/app_shell.dart';
import '../widgets/batang.dart';
import '../widgets/bingkai.dart';
import '../widgets/ikon_kotak.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/lembar_buka_kasir.dart';
import '../widgets/lembar_riwayat_shift.dart';
import '../widgets/lembar_struk.dart';
import '../widgets/lembar_tutup_kasir.dart';
import '../widgets/lencana.dart';
import '../widgets/rangka.dart';
import 'piutang_screen.dart';
import 'produk_screen.dart';

/// Beranda.
///
/// Susunannya menuruni satu tangga kepentingan, bukan deretan kartu setara:
///
///   1. sapaan            siapa dan toko apa
///   2. **panel tinta**   angka hari ini + tombol Buka kasir, satu objek
///   3. perlu perhatian   hanya muncul kalau memang ada
///   4. aksi cepat        empat tujuan sekunder, seragam
///   5. transaksi         bukti bahwa hari ini berjalan
///
/// Gagasan intinya ada di nomor dua: **angka dan aksinya satu benda.** Kartu
/// statistik yang terpisah dari tombolnya memaksa mata melompat dua kali untuk
/// satu keputusan ("ramai tidak hari ini? ya sudah, buka kasir"). Digabung,
/// keputusan itu selesai dalam satu pandangan — dan itulah satu-satunya
/// permukaan fokus yang boleh ada di layar ini.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key, required this.onBukaKasir, this.onKeTab});

  final VoidCallback onBukaKasir;

  /// Pindah tab dari aksi cepat. Null saat dipakai di luar kerangka bertab.
  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return Bingkai<RingkasanBeranda>(
      ambil: Repositori.beranda,
      rangka: ListView(
        padding: padding,
        children: const [
          _Sapaan(),
          SizedBox(height: Jarak.sm),
          RangkaPanel(tinggi: 320),
          SizedBox(height: Jarak.md),
          RangkaDaftar(baris: 3),
        ],
      ),
      isi: (context, r) =>
          _Isi(ringkasan: r, onBukaKasir: onBukaKasir, onKeTab: onKeTab),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({
    required this.ringkasan,
    required this.onBukaKasir,
    required this.onKeTab,
  });

  final RingkasanBeranda ringkasan;
  final VoidCallback onBukaKasir;
  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);
    final duaKolom = MediaQuery.sizeOf(context).width >= 900;

    final kiri = <Widget>[
      _PanelHariIni(ringkasan: ringkasan, onBukaKasir: onBukaKasir),
      const SizedBox(height: Jarak.md),
      _AksiCepat(onKeTab: onKeTab),
    ];

    final kanan = <Widget>[
      if (_adaPerhatian(ringkasan)) ...[
        _PerluPerhatian(ringkasan: ringkasan, onKeTab: onKeTab),
        const SizedBox(height: Jarak.md),
      ],
      _TransaksiTerakhir(daftar: ringkasan.terakhir, onKeTab: onKeTab),
    ];

    return ListView(
      padding: padding,
      children: [
        const _Sapaan(),
        const SizedBox(height: Jarak.sm),
        if (duaKolom)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: kiri,
                ),
              ),
              const SizedBox(width: Jarak.md),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: kanan,
                ),
              ),
            ],
          )
        else ...[
          ...kiri,
          const SizedBox(height: Jarak.md),
          ...kanan,
        ],
      ],
    );
  }

  static bool _adaPerhatian(RingkasanBeranda r) =>
      r.adaMasalahStok || r.adaPiutang || r.langganan.sisaHari <= 7;
}

// ---------------------------------------------------------------------------

class _Sapaan extends StatelessWidget {
  const _Sapaan();

  String get _salam {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Selamat pagi';
    if (jam < 15) return 'Selamat siang';
    if (jam < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.aksen.isian,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            inisial(profilContoh.nama),
            style: context.teks.titleSmall?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: Jarak.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _salam,
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                tokoContoh.nama,
                style: context.teks.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _menyusul(context, 'Notifikasi'),
          icon: const Icon(Icons.notifications_none),
          tooltip: 'Notifikasi',
        ),
      ],
    );
  }
}

/// Satu-satunya permukaan fokus di seluruh layar.
class _PanelHariIni extends StatelessWidget {
  const _PanelHariIni({required this.ringkasan, required this.onBukaKasir});

  final RingkasanBeranda ringkasan;
  final VoidCallback onBukaKasir;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: a.fokus,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        boxShadow: a.bayanganKartu,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Penjualan hari ini',
                  style: context.teks.labelSmall?.copyWith(
                    color: a.atasFokusRedup,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              _SelisihKemarin(persen: ringkasan.selisihPersen),
            ],
          ),
          const SizedBox(height: Jarak.xs2),
          // Angka panjang mengecil sendiri daripada terpotong. "Rp 1.234.000"
          // pada 320 px sudah menyentuh tepi.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(ringkasan.omzet),
              style: context.teks.displaySmall?.copyWith(
                color: a.atasFokus,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: Jarak.sm),
          Percikan(
            nilai: ringkasan.tujuhHari,
            warna: a.atasFokusRedup.withValues(alpha: 0.35),
            warnaAkhir: a.atasFokus,
          ),
          const SizedBox(height: 6),
          Text(
            'Tujuh hari terakhir',
            style: context.teks.labelSmall?.copyWith(
              color: a.atasFokusRedup,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: Jarak.sm),
          Divider(height: 1, color: a.atasFokusRedup.withValues(alpha: 0.22)),
          const SizedBox(height: Jarak.xs),

          if (ringkasan.belumAdaPenjualan)
            Text(
              'Belum ada transaksi hari ini.',
              style: context.teks.bodySmall?.copyWith(color: a.atasFokusRedup),
            )
          else
            Row(
              children: [
                // Keduanya Expanded — pada 320 px, dua label berdampingan yang
                // berukuran alami sudah cukup untuk meluber keluar panel.
                Expanded(
                  child: _AngkaKecil(
                    label: 'Transaksi',
                    nilai: '${ringkasan.transaksi}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: Jarak.xs),
                  color: a.atasFokusRedup.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _AngkaKecil(
                    label: 'Item terjual',
                    nilai: '${ringkasan.item}',
                  ),
                ),
              ],
            ),
          const SizedBox(height: Jarak.md),
          const SizedBox(height: Jarak.md),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onBukaKasir,
              icon: const Icon(Icons.point_of_sale, size: 20),
              label: const Text('Buka kasir'),
              style: FilledButton.styleFrom(
                backgroundColor: a.atasFokus,
                foregroundColor: a.fokus,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pil selisih terhadap kemarin.
///
/// Hilang sama sekali kalau kemarin nol — pertumbuhan dari nol bukan "naik
/// 100%", itu tidak terdefinisi, dan menampilkan angka apa pun di situ adalah
/// mengarang. Ini juga satu-satunya tempat kroma boleh masuk ke panel tinta,
/// karena naik/turun memang berstatus.
class _SelisihKemarin extends StatelessWidget {
  const _SelisihKemarin({required this.persen});

  final int? persen;

  @override
  Widget build(BuildContext context) {
    if (persen == null) return const SizedBox.shrink();

    final a = context.aksen;
    final naik = persen! >= 0;
    final warna = naik ? a.sukses : a.bahaya;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Lengkung.bulat),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            naik ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: warna,
          ),
          const SizedBox(width: 4),
          Text(
            '${naik ? '+' : ''}$persen%',
            style: context.teks.labelSmall?.copyWith(
              color: warna,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _AngkaKecil extends StatelessWidget {
  const _AngkaKecil({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nilai,
          style: context.teks.titleMedium?.copyWith(
            color: context.aksen.atasFokus,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: context.teks.bodySmall?.copyWith(
            color: context.aksen.atasFokusRedup,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Muncul HANYA kalau ada yang perlu diperhatikan.
///
/// Kartu peringatan yang selalu ada berhenti dibaca dalam tiga hari. Yang
/// datang dan pergi tetap terbaca setahun kemudian.
class _PerluPerhatian extends StatelessWidget {
  const _PerluPerhatian({required this.ringkasan, required this.onKeTab});

  final RingkasanBeranda ringkasan;
  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    final l = ringkasan.langganan;
    final baris = <Widget>[
      if (l.sisaHari <= 7)
        BarisDaftar(
          awalan: IkonKotak(
            Icons.workspace_premium_outlined,
            nada: l.sisaHari < 0 ? NadaIkon.bahaya : NadaIkon.peringatan,
            ukuran: 36,
          ),
          judul: 'Langganan ${l.durasi.label}',
          keterangan: sisaHari(l.sisaHari),
          bawahAkhiran: Lencana.langganan(l.status),
          onTekan: () => onKeTab?.call(4),
        ),
      if (ringkasan.produkHabis > 0)
        BarisDaftar(
          awalan: const IkonKotak(
            Icons.remove_shopping_cart_outlined,
            nada: NadaIkon.bahaya,
            ukuran: 36,
          ),
          judul: '${ringkasan.produkHabis} produk habis',
          keterangan: 'Tidak bisa dijual sampai stok diisi',
          onTekan: () => onKeTab?.call(1),
        ),
      if (ringkasan.produkMenipis > 0)
        BarisDaftar(
          awalan: const IkonKotak(
            Icons.inventory_outlined,
            nada: NadaIkon.peringatan,
            ukuran: 36,
          ),
          judul: '${ringkasan.produkMenipis} produk menipis',
          keterangan: 'Sisa lima atau kurang',
          onTekan: () => onKeTab?.call(1),
        ),
      if (ringkasan.adaPiutang)
        BarisDaftar(
          awalan: const IkonKotak(
            Icons.schedule_outlined,
            nada: NadaIkon.peringatan,
            ukuran: 36,
          ),
          judul: '${ringkasan.piutangJumlah} struk belum dibayar',
          keterangan: 'Bayar nanti, menunggu ditagih',
          akhiran: rupiah(ringkasan.piutangTotal),
          onTekan: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PiutangScreen()),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JudulBagian('Perlu perhatian'),
        KartuDaftar(anak: baris),
      ],
    );
  }
}

class _AksiCepat extends StatelessWidget {
  const _AksiCepat({required this.onKeTab});

  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SesiKasir?>(
      valueListenable: Repositori.sesiKasirAktif,
      builder: (context, sesi, _) {
        final aksi = <(IconData, String, VoidCallback)>[
          if (sesi == null)
            (
              Icons.storefront_outlined,
              'Buka kasir',
              () async {
                final profil = await Repositori.profil();
                if (!context.mounted) return;
                await LembarBukaKasir.tampilkan(
                  context,
                  profilDefault: profil,
                );
              },
            )
          else
            (
              Icons.no_encryption_gmailerrorred_outlined,
              'Tutup kasir',
              () => LembarTutupKasir.tampilkan(context, sesi: sesi),
            ),
          (
            Icons.history_toggle_off,
            'Riwayat shift',
            () => LembarRiwayatShift.tampilkan(context),
          ),
          (
            Icons.add_box_outlined,
            'Tambah produk',
            () => ProdukScreen.bukaFormulir(context),
          ),
          (Icons.inventory_2_outlined, 'Cek stok', () => onKeTab?.call(1)),
          (Icons.print_outlined, 'Cetak ulang struk', () => onKeTab?.call(2)),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const JudulBagian('Aksi cepat'),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: Jarak.xs2,
                crossAxisSpacing: Jarak.xs2,
                mainAxisExtent: 76,
              ),
              itemCount: aksi.length,
              itemBuilder: (context, i) {
                final (ikon, label, onTekan) = aksi[i];
                return _PetakAksi(ikon: ikon, label: label, onTekan: onTekan);
              },
            ),
          ],
        );
      },
    );
  }
}

class _PetakAksi extends StatelessWidget {
  const _PetakAksi({
    required this.ikon,
    required this.label,
    required this.onTekan,
  });

  final IconData ikon;
  final String label;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.warna.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Lengkung.kontrol),
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Jarak.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Lengkung.kontrol),
            border: Border.all(color: context.warna.outline),
          ),
          child: Row(
            children: [
              IkonKotak(ikon, ukuran: 34),
              const SizedBox(width: Jarak.xs2),
              Expanded(
                child: Text(
                  label,
                  style: context.teks.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransaksiTerakhir extends StatelessWidget {
  const _TransaksiTerakhir({required this.daftar, required this.onKeTab});

  final List<Transaksi> daftar;
  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JudulBagian(
          'Transaksi terakhir',
          aksi: daftar.isEmpty
              ? null
              : TextButton(
                  onPressed: () => onKeTab?.call(2),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Semua'),
                ),
        ),
        if (daftar.isEmpty)
          const Keadaan(
            ikon: Icons.receipt_long_outlined,
            judul: 'Belum ada penjualan',
            keterangan:
                'Transaksi pertama akan muncul di sini begitu Anda '
                'menutup satu pesanan di kasir.',
          )
        else
          KartuDaftar(
            anak: [for (final t in daftar) _BarisTransaksi(transaksi: t)],
          ),
      ],
    );
  }
}

class _BarisTransaksi extends StatelessWidget {
  const _BarisTransaksi({required this.transaksi});

  final Transaksi transaksi;

  @override
  Widget build(BuildContext context) {
    final (ikon, nada) = switch (transaksi.status) {
      StatusTransaksi.batal => (Icons.close, NadaIkon.bahaya),
      StatusTransaksi.ditahan => (Icons.schedule_outlined, NadaIkon.peringatan),
      StatusTransaksi.selesai => (Icons.check, NadaIkon.sukses),
    };

    return BarisDaftar(
      awalan: IkonKotak(ikon, nada: nada, ukuran: 36),
      judul: transaksi.nomorStruk,
      keterangan: transaksi.piutang
          ? '${relatif(transaksi.waktu)} · '
                '${transaksi.pelanggan ?? 'Tanpa nama'}'
          : '${relatif(transaksi.waktu)} · ${transaksi.metode.label} · '
                '${transaksi.jumlahItem} item',
      akhiran: rupiah(transaksi.total),
      onTekan: () => LembarStruk.tampilkan(context, transaksi),
    );
  }
}

void _menyusul(BuildContext context, String apa) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$apa menyusul.')));
}
