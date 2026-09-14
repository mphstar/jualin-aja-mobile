import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../data/sesi_kasir.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/app_shell.dart';
import '../widgets/avatar_online.dart';
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

/// Beranda aplikasi POS.
///
/// Ringkas dan menonjol: satu kartu "Activity" (grafik 7 hari + omzet hari
/// ini), satu kartu "Total", tiga angka penting ber-bar warna, lalu aksi shift
/// kasir dan riwayat transaksi — persis urutan yang dipakai kasir setiap hari.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key, required this.onBukaKasir, this.onKeTab});

  final VoidCallback onBukaKasir;
  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return Bingkai<RingkasanBeranda>(
      // Akar tab: kalau server tidak terjangkau, seluruh halaman Beranda
      // diganti satu tampilan galat — bukan sapaan dan panel setengah jadi.
      bentukGalat: BentukGalat.halaman,
      // Kepala halaman tetap tampil saat isinya gagal: layar yang kehilangan
      // sapaannya terbaca seperti aplikasi yang rusak, bukan seperti koneksi
      // yang sedang bermasalah.
      pembungkusGalat: (galat) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              0,
            ),
            child: const _HeaderBeranda(),
          ),
          Expanded(child: galat),
        ],
      ),
      ambil: Repositori.beranda,
      rangka: ListView(
        padding: padding,
        children: const [
          _HeaderBeranda(),
          SizedBox(height: Jarak.sm),
          RangkaPanel(tinggi: 150),
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
    final totalMinggu = ringkasan.tujuhHari.fold(0, (a, b) => a + b);

    return ListView(
      padding: padding,
      children: [
        const _HeaderBeranda(),
        const SizedBox(height: Jarak.sm),
        // Dua kartu teratas berbagi lebar halaman, bukan memakai lebar tetap.
        // Dengan lebar tetap, di ponsel kartu kedua terpotong separuh dan di
        // jendela lebar keduanya berhenti jauh sebelum tepi kanan — tepinya
        // tidak pernah sejajar dengan kartu-kartu di bawahnya. Perbandingan
        // 248:190 dipertahankan supaya kartu omzet tetap yang paling besar.
        SizedBox(
          height: 176,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 248,
                child: _KartuAktivitas(
                  omzet: ringkasan.omzet,
                  deret: ringkasan.tujuhHari,
                  selisih: ringkasan.selisihPersen,
                ),
              ),
              const SizedBox(width: Jarak.xs),
              Expanded(
                flex: 190,
                child: _KartuTotal(
                  total: totalMinggu,
                  transaksi: ringkasan.transaksi,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.md),
        _KartuStatistik(
          transaksi: ringkasan.transaksi,
          omzet: ringkasan.omzet,
          pending: ringkasan.piutangJumlah,
          selisih: ringkasan.selisihPersen,
        ),
        const SizedBox(height: Jarak.md),
        _AksiCepat(onKeTab: onKeTab),
        const SizedBox(height: Jarak.md),
        _SpandukShift(onBukaKasir: onBukaKasir),
        if (_adaPerhatian(ringkasan)) ...[
          const SizedBox(height: Jarak.md),
          _PerluPerhatian(ringkasan: ringkasan, onKeTab: onKeTab),
        ],
        const SizedBox(height: Jarak.md),
        _TransaksiTerakhir(daftar: ringkasan.terakhir, onKeTab: onKeTab),
      ],
    );
  }

  static bool _adaPerhatian(RingkasanBeranda r) =>
      r.adaMasalahStok || r.adaPiutang || r.langganan.sisaHari <= 7;
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HeaderBeranda extends StatefulWidget {
  const _HeaderBeranda();

  @override
  State<_HeaderBeranda> createState() => _HeaderBerandaState();
}

class _HeaderBerandaState extends State<_HeaderBeranda> {
  late final Future<({Profil profil, Toko toko})> _muat = _ambil();

  String get _salam {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Selamat pagi';
    if (jam < 15) return 'Selamat siang';
    if (jam < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  Future<({Profil profil, Toko toko})> _ambil() async {
    final p = await Repositori.profil();
    final t = await Repositori.toko();
    return (profil: p, toko: t);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Profil profil, Toko toko})>(
      future: _muat,
      builder: (context, snapshot) {
        final namaToko = snapshot.data?.toko.nama ?? '';
        final namaProfil = snapshot.data?.profil.nama ?? '';

        return Row(
          children: [
            AvatarOnline(nama: namaProfil, ukuran: 44),
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
                  if (namaToko.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Rangka(lebar: 140, tinggi: 16),
                      ),
                    )
                  else
                    Text(
                      namaToko,
                      style: context.teks.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: Jarak.xs2),
            const _StatusKasirPill(),
          ],
        );
      },
    );
  }
}

class _StatusKasirPill extends StatelessWidget {
  const _StatusKasirPill();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SesiKasir?>(
      valueListenable: Repositori.sesiKasirAktif,
      builder: (context, sesi, _) {
        final buka = sesi != null;
        final a = context.aksen;

        return Material(
          color: buka ? a.suksesLembut : context.warna.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Lengkung.bulat),
          child: InkWell(
            onTap: buka
                ? () => LembarTutupKasir.tampilkan(context, sesi: sesi)
                : () async {
                    final profil = await Repositori.profil();
                    if (!context.mounted) return;
                    await LembarBukaKasir.tampilkan(
                      context,
                      profilDefault: profil,
                    );
                  },
            borderRadius: BorderRadius.circular(Lengkung.bulat),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Jarak.xs,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: buka ? a.sukses : context.warna.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    buka ? 'Shift Buka' : 'Shift Tutup',
                    style: context.teks.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: buka ? a.sukses : context.warna.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu Activity & Total
// ---------------------------------------------------------------------------

class _KartuAktivitas extends StatelessWidget {
  const _KartuAktivitas({
    required this.omzet,
    required this.deret,
    required this.selisih,
  });

  final int omzet;
  final List<int> deret;
  final int? selisih;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Activity',
                    style: context.teks.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _BadgePersen(persen: selisih),
              ],
            ),
            const SizedBox(height: Jarak.xs2),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: _GarisBisikan(nilai: deret, warna: context.warna.onSurface),
            ),
            const SizedBox(height: Jarak.xs2),
            Text(
              'Penjualan hari ini',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                rupiah(omzet),
                style: context.teks.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuTotal extends StatelessWidget {
  const _KartuTotal({required this.total, required this.transaksi});

  final int total;
  final int transaksi;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total 7 hari',
              style: context.teks.labelSmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Jarak.xs2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                rupiah(total),
                style: context.teks.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: Jarak.xs2),
            Text(
              '$transaksi transaksi',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tiga angka penting
// ---------------------------------------------------------------------------

class _KartuStatistik extends StatelessWidget {
  const _KartuStatistik({
    required this.transaksi,
    required this.omzet,
    required this.pending,
    required this.selisih,
  });

  final int transaksi;
  final int omzet;
  final int pending;
  final int? selisih;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _BarisStatistik(
            warna: context.aksen.sukses,
            nilai: angka(transaksi),
            label: 'Total Transaksi',
            badge: _BadgePersen(persen: selisih),
          ),
          Divider(height: 1, color: context.warna.outline),
          _BarisStatistik(
            warna: context.warna.onSurface,
            nilai: rupiah(omzet),
            label: 'Total Penjualan',
          ),
          Divider(height: 1, color: context.warna.outline),
          _BarisStatistik(
            warna: context.aksen.bahaya,
            nilai: angka(pending),
            label: 'Menunggu Dibayar',
          ),
        ],
      ),
    );
  }
}

class _BarisStatistik extends StatelessWidget {
  const _BarisStatistik({
    required this.warna,
    required this.nilai,
    required this.label,
    this.badge,
  });

  final Color warna;
  final String nilai;
  final String label;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Jarak.sm, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: warna,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Jarak.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    nilai,
                    style: context.teks.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: Jarak.xs),
            badge!,
          ],
        ],
      ),
    );
  }
}

class _BadgePersen extends StatelessWidget {
  const _BadgePersen({required this.persen});

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
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Lengkung.bulat),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(naik ? Icons.trending_up : Icons.trending_down, size: 14, color: warna),
          const SizedBox(width: 4),
          Text(
            '${naik ? '+' : ''}$persen%',
            style: context.teks.labelSmall?.copyWith(
              color: warna,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grafik garis mini (sparkline) tanpa dependensi chart.
class _GarisBisikan extends StatelessWidget {
  const _GarisBisikan({required this.nilai, required this.warna});

  final List<int> nilai;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PelukisGaris(nilai, warna));
  }
}

class _PelukisGaris extends CustomPainter {
  _PelukisGaris(this.nilai, this.warna);

  final List<int> nilai;
  final Color warna;

  @override
  void paint(Canvas kanvas, Size ukuran) {
    if (nilai.length < 2) return;

    final maks = math.max(1, nilai.reduce(math.max));
    final min = math.min(0, nilai.reduce(math.min));
    final rentang = (maks - min).toDouble();
    final jarak = ukuran.width / (nilai.length - 1);

    Offset titik(int i) {
      final x = jarak * i;
      final ternormal = (nilai[i] - min) / (rentang == 0 ? 1 : rentang);
      final y = ukuran.height - (ternormal * ukuran.height * 0.82) - ukuran.height * 0.09;
      return Offset(x, y);
    }

    final path = Path()..moveTo(titik(0).dx, titik(0).dy);
    for (var i = 1; i < nilai.length; i++) {
      path.lineTo(titik(i).dx, titik(i).dy);
    }

    // Isi halus di bawah garis.
    final isi = Path.from(path)
      ..lineTo(ukuran.width, ukuran.height)
      ..lineTo(0, ukuran.height)
      ..close();

    kanvas.drawPath(
      isi,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [warna.withValues(alpha: 0.14), warna.withValues(alpha: 0)],
        ).createShader(Offset.zero & ukuran),
    );

    kanvas.drawPath(
      path,
      Paint()
        ..color = warna
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    // Titik di ujung (hari terakhir).
    kanvas.drawCircle(titik(nilai.length - 1), 3.2, Paint()..color = warna);
  }

  @override
  bool shouldRepaint(covariant _PelukisGaris lama) =>
      lama.warna != warna || lama.nilai != nilai;
}

// ---------------------------------------------------------------------------
// Aksi cepat
// ---------------------------------------------------------------------------

class _AksiCepat extends StatelessWidget {
  const _AksiCepat({required this.onKeTab});

  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    final aksi = <(IconData, String, VoidCallback)>[
      (
        Icons.add_box_outlined,
        'Tambah Produk',
        () => ProdukScreen.bukaFormulir(context),
      ),
      (
        Icons.inventory_2_outlined,
        'Kelola Stok',
        () => onKeTab?.call(1),
      ),
      (
        Icons.history_rounded,
        'Riwayat Sesi',
        () => LembarRiwayatShift.tampilkan(context),
      ),
      (
        Icons.print_outlined,
        'Cetak Struk',
        () => onKeTab?.call(2),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JudulBagian('Aksi cepat'),
        // Lebar petak dibatasi, bukan dipatok dua kolom. Dengan dua kolom
        // tetap, di jendela lebar tiap petak ikut melebar — dan karena
        // tingginya diturunkan dari lebar (childAspectRatio), petaknya jadi
        // setinggi kartu besar, bukan lagi tombol. Di ponsel hasilnya tetap
        // dua kolom seperti sekarang.
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisSpacing: Jarak.xs,
            crossAxisSpacing: Jarak.xs,
            childAspectRatio: 3.2,
          ),
          children: [
            for (final (ikon, label, onTekan) in aksi)
              _AksiTile(ikon: ikon, label: label, onTekan: onTekan),
          ],
        ),
      ],
    );
  }
}

class _AksiTile extends StatelessWidget {
  const _AksiTile({
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Jarak.xs, vertical: 8),
          child: Row(
            children: [
              IkonKotak(ikon, ukuran: 36),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.teks.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shift kasir (aksi utama)
// ---------------------------------------------------------------------------

class _SpandukShift extends StatelessWidget {
  const _SpandukShift({required this.onBukaKasir});

  final VoidCallback onBukaKasir;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SesiKasir?>(
      valueListenable: Repositori.sesiKasirAktif,
      builder: (context, sesi, _) =>
          sesi == null ? _kartuTutup(context) : _kartuBuka(context, sesi),
    );
  }

  Widget _kartuTutup(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buka kasir untuk mulai berjualan',
              style: context.teks.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Masukkan modal awal, lalu mulai mencatat transaksi & pesanan.',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Jarak.md),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final profil = await Repositori.profil();
                  if (!context.mounted) return;
                  await LembarBukaKasir.tampilkan(
                    context,
                    profilDefault: profil,
                  );
                },
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Buka Kasir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuBuka(BuildContext context, SesiKasir sesi) {
    final a = context.aksen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IkonKotak(
                  Icons.point_of_sale_rounded,
                  nada: NadaIkon.sukses,
                  ukuran: 40,
                ),
                const SizedBox(width: Jarak.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: a.sukses,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Shift Kasir Aktif',
                            style: context.teks.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: a.sukses,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sesi.namaKasir} · Sejak ${jam(sesi.waktuBuka)} · '
                        '${rupiah(sesi.totalPenjualan)}',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Jarak.md),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: onBukaKasir,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Lengkung.kontrol),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                      label: const Text('Mulai Penjualan'),
                    ),
                  ),
                ),
                const SizedBox(width: Jarak.xs),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          LembarTutupKasir.tampilkan(context, sesi: sesi),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.warna.onSurfaceVariant,
                        side: BorderSide(color: context.warna.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Lengkung.kontrol),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.lock_reset_rounded, size: 16),
                      label: const Text('Tutup Shift'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Perlu perhatian
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Transaksi terakhir
// ---------------------------------------------------------------------------

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
                  child: const Text('Lihat Semua'),
                ),
        ),
        if (daftar.isEmpty)
          const Keadaan(
            ikon: Icons.receipt_long_outlined,
            judul: 'Belum ada penjualan hari ini',
            keterangan:
                'Transaksi pertama akan otomatis tampil di sini begitu '
                'pesanan di kasir diselesaikan.',
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
          ? '${relatif(transaksi.waktu)} · ${transaksi.pelanggan ?? 'Tanpa nama'}'
          : '${relatif(transaksi.waktu)} · ${transaksi.metode.label} · '
              '${transaksi.jumlahItem} item',
      akhiran: rupiah(transaksi.total),
      onTekan: () => LembarStruk.tampilkan(context, transaksi),
    );
  }
}
