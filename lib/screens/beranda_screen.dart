import 'package:flutter/material.dart';

import '../data/contoh.dart';
import '../data/model.dart';
import '../data/repositori.dart';
import '../data/sesi_kasir.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/app_shell.dart';
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

/// Beranda Aplikasi POS yang intuitif & ramah pengguna awal.
///
/// Tata letak dirancang bersih dan mudah dipahami:
///   1. Header Sapaan & Status Shift Kasir
///   2. Spanduk Utama Aksi Shift (Buka Kasir / Kasir Aktif)
///   3. Panduan Langkah Awal Toko (tampil jika belum ada penjualan)
///   4. Ringkasan Statistik Penjualan Hari Ini (Omzet, Transaksi, Item)
///   5. Pintasan Aksi Cepat
///   6. Perlu Perhatian (bila ada stok habis/piutang)
///   7. Riwayat Transaksi Terakhir
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
          _SapaanHeader(),
          SizedBox(height: Jarak.sm),
          RangkaPanel(tinggi: 180),
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
      _SpandukUtamaShift(onBukaKasir: onBukaKasir),
      const SizedBox(height: Jarak.md),
      if (ringkasan.belumAdaPenjualan) ...[
        _PanduanAwalToko(onKeTab: onKeTab),
        const SizedBox(height: Jarak.md),
      ],
      _KartuStatistikRingkas(ringkasan: ringkasan),
      const SizedBox(height: Jarak.md),
      _AksiCepatGrid(onKeTab: onKeTab),
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
        const _SapaanHeader(),
        const SizedBox(height: Jarak.md),
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
// Header Sapaan & Profil Toko
// ---------------------------------------------------------------------------

class _SapaanHeader extends StatelessWidget {
  const _SapaanHeader();

  String get _salam {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Selamat pagi ☀️';
    if (jam < 15) return 'Selamat siang 🌤️';
    if (jam < 18) return 'Selamat sore 🌆';
    return 'Selamat malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Profil profil, Toko toko})>(
      future: () async {
        try {
          final p = await Repositori.profil();
          final t = await Repositori.toko();
          return (profil: p, toko: t);
        } catch (_) {
          return (profil: profilContoh, toko: tokoContoh);
        }
      }(),
      builder: (context, snapshot) {
        final profilNama = snapshot.data?.profil.nama ?? profilContoh.nama;
        final tokoNama = snapshot.data?.toko.nama ?? tokoContoh.nama;

        return Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.warna.primaryContainer,
                    context.warna.surfaceContainerHigh,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.warna.primary.withAlpha(80),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                inisial(profilNama),
                style: context.teks.titleMedium?.copyWith(
                  color: context.warna.primary,
                  fontWeight: FontWeight.bold,
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
                    tokoNama,
                    style: context.teks.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Jarak.xs2),
            _StatusKasirPill(),
          ],
        );
      },
    );
  }
}

/// Pill status kasir kecil di header
class _StatusKasirPill extends StatelessWidget {
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
                      fontWeight: FontWeight.bold,
                      color: buka
                          ? a.sukses
                          : context.warna.onSurfaceVariant,
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
// Spanduk Utama Shift Kasir (Aksi Pertama yang Jelas)
// ---------------------------------------------------------------------------

class _SpandukUtamaShift extends StatelessWidget {
  const _SpandukUtamaShift({required this.onBukaKasir});

  final VoidCallback onBukaKasir;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;

    return ValueListenableBuilder<SesiKasir?>(
      valueListenable: Repositori.sesiKasirAktif,
      builder: (context, sesi, _) {
        final buka = sesi != null;

        if (!buka) {
          // Kasir sedang Tutup -> Ajak pengguna Buka Kasir
          return Container(
            padding: const EdgeInsets.all(Jarak.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.warna.primaryContainer,
                  context.warna.surfaceContainerHigh,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Lengkung.panel),
              border: Border.all(
                color: context.warna.primary.withAlpha(60),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.warna.primary.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: context.warna.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.warna.primary.withAlpha(70),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: context.warna.onPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: Jarak.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Kasir Belum Buka',
                            style: context.teks.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Buka kasir untuk mulai menerima transaksi & mencatat pesanan',
                            style: context.teks.bodySmall?.copyWith(
                              color: context.warna.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Jarak.md),
                Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Lengkung.bulat),
                    boxShadow: [
                      BoxShadow(
                        color: context.warna.primary.withAlpha(70),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Buka Shift Kasir Sekarang'),
                  ),
                ),
              ],
            ),
          );
        }

        // Kasir sedang Buka -> Tampilan Bersih, Ringkas & Elegan
        return Container(
          padding: const EdgeInsets.all(Jarak.md),
          decoration: BoxDecoration(
            color: context.warna.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(Lengkung.panel),
            border: Border.all(color: a.sukses.withAlpha(80)),
            boxShadow: [
              BoxShadow(
                color: a.sukses.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: a.suksesLembut,
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.point_of_sale_rounded,
                      color: a.sukses,
                      size: 24,
                    ),
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
                                fontWeight: FontWeight.bold,
                                color: a.sukses,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sesi.namaKasir} · Sejak ${jam(sesi.waktuBuka)} · Omzet: ${rupiah(sesi.totalPenjualan)}',
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
                          backgroundColor: a.sukses,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Lengkung.kontrol),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                          side: BorderSide(
                            color: context.warna.outline,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Lengkung.kontrol),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: Icon(
                          Icons.lock_reset_rounded,
                          size: 16,
                          color: context.warna.onSurfaceVariant,
                        ),
                        label: const Text('Tutup Shift'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Panduan Langkah Awal (Khusus Pengguna / Toko Baru)
// ---------------------------------------------------------------------------

class _PanduanAwalToko extends StatelessWidget {
  const _PanduanAwalToko({required this.onKeTab});

  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        border: Border.all(color: context.warna.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_objects_outlined,
                color: context.warna.primary,
                size: 22,
              ),
              const SizedBox(width: Jarak.xs2),
              Text(
                'Langkah Awal Toko Anda',
                style: context.teks.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.xs),
          Text(
            'Ikuti 3 langkah sederhana berikut untuk mulai berjualan:',
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Jarak.sm),

          // Langkah 1: Tambah Produk
          _BarisLangkah(
            nomor: '1',
            judul: 'Tambah Produk Jualan',
            deskripsi: 'Daftarkan barang atau menu yang akan dijual',
            selesai: false,
            onTekan: () => ProdukScreen.bukaFormulir(context),
            labelAksi: 'Tambah Produk',
          ),
          const Divider(height: Jarak.md),

          // Langkah 2: Buka Shift Kasir
          _BarisLangkah(
            nomor: '2',
            judul: 'Buka Shift Kasir',
            deskripsi: 'Masukkan modal awal kasir untuk mulai transaksi',
            selesai: false,
            onTekan: () async {
              final profil = await Repositori.profil();
              if (!context.mounted) return;
              await LembarBukaKasir.tampilkan(context, profilDefault: profil);
            },
            labelAksi: 'Buka Kasir',
          ),
          const Divider(height: Jarak.md),

          // Langkah 3: Catat Transaksi
          _BarisLangkah(
            nomor: '3',
            judul: 'Catat Penjualan Pertama',
            deskripsi: 'Pilih produk di layar kasir & cetak struk pembeli',
            selesai: false,
            onTekan: () => onKeTab?.call(0),
            labelAksi: 'Buka Kasir',
          ),
        ],
      ),
    );
  }
}

class _BarisLangkah extends StatelessWidget {
  const _BarisLangkah({
    required this.nomor,
    required this.judul,
    required this.deskripsi,
    required this.selesai,
    required this.onTekan,
    required this.labelAksi,
  });

  final String nomor;
  final String judul;
  final String deskripsi;
  final bool selesai;
  final VoidCallback onTekan;
  final String labelAksi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: selesai
                ? context.aksen.sukses
                : context.warna.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            nomor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selesai
                  ? Colors.white
                  : context.warna.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: Jarak.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: context.teks.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                deskripsi,
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Jarak.xs2),
        TextButton(
          onPressed: onTekan,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(labelAksi),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu Statistik Penjualan Hari Ini (Bersih & Mudah Dibaca)
// ---------------------------------------------------------------------------

class _KartuStatistikRingkas extends StatelessWidget {
  const _KartuStatistikRingkas({required this.ringkasan});

  final RingkasanBeranda ringkasan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.sm),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        border: Border.all(color: context.warna.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RINGKASAN PENJUALAN HARI INI',
                  style: context.teks.labelSmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _SelisihKemarin(persen: ringkasan.selisihPersen),
            ],
          ),
          const SizedBox(height: Jarak.xs2),
          Text(
            rupiah(ringkasan.omzet),
            style: context.teks.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.warna.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: Jarak.sm),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(Jarak.xs),
                  decoration: BoxDecoration(
                    color: context.warna.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Transaksi',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ringkasan.transaksi}',
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(Jarak.xs),
                  decoration: BoxDecoration(
                    color: context.warna.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Terjual',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ringkasan.item}',
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        color: warna.withAlpha(25),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pintasan Aksi Cepat
// ---------------------------------------------------------------------------

class _AksiCepatGrid extends StatelessWidget {
  const _AksiCepatGrid({required this.onKeTab});

  final ValueChanged<int>? onKeTab;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SesiKasir?>(
      valueListenable: Repositori.sesiKasirAktif,
      builder: (context, sesi, _) {
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
            Icons.history_toggle_off,
            'Riwayat Shift',
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
            const JudulBagian('Pintasan Aksi'),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: Jarak.xs2,
                crossAxisSpacing: Jarak.xs2,
                mainAxisExtent: 68,
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
              IkonKotak(ikon, ukuran: 32),
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

// ---------------------------------------------------------------------------
// Perlu Perhatian
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
// Riwayat Transaksi Terakhir
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
                'Transaksi pertama Anda akan otomatis tampil di sini begitu pesanan di kasir diselesaikan.',
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
          : '${relatif(transaksi.waktu)} · ${transaksi.metode.label} · ${transaksi.jumlahItem} item',
      akhiran: rupiah(transaksi.total),
      onTekan: () => LembarStruk.tampilkan(context, transaksi),
    );
  }
}
