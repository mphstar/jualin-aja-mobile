import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/ilustrasi.dart';
import '../widgets/peraga.dart';
import '../widgets/tombol_pil.dart';

/// Alur pembuka: tiga slide sambutan, lalu dua pertanyaan penyiapan toko.
///
/// Kenapa ada sama sekali. Layar masuk tidak menjelaskan apa pun — ia menuntut
/// email dan kata sandi dari orang yang belum tahu untuk apa. Alur ini menjawab
/// "aplikasi ini buat apa" lebih dulu, lalu mengumpulkan dua keping data yang
/// nantinya benar-benar mengubah isi aplikasi: jenis usaha menentukan kategori
/// awal, dan keluhan utama menentukan apa yang disorot di Beranda.
///
/// Dua pertanyaan, bukan tujuh. Setiap layar tambahan sebelum orang melihat
/// nilai produknya adalah tempat untuk berhenti.
class SambutanScreen extends StatefulWidget {
  const SambutanScreen({
    super.key,
    required this.onSelesai,
    required this.onSudahPunyaAkun,
  });

  /// Dipanggil setelah kedua pertanyaan dijawab.
  final VoidCallback onSelesai;

  /// Jalan pintas untuk pengguna lama — langsung ke layar masuk.
  final VoidCallback onSudahPunyaAkun;

  @override
  State<SambutanScreen> createState() => _SambutanScreenState();
}

class _SambutanScreenState extends State<SambutanScreen> {
  final _pengendali = PageController();
  int _slide = 0;

  @override
  void dispose() {
    _pengendali.dispose();
    super.dispose();
  }

  void _mulai() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PertanyaanUsahaScreen(onSelesai: widget.onSelesai),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pengendali,
                    itemCount: _slideSambutan.length,
                    onPageChanged: (i) => setState(() => _slide = i),
                    itemBuilder: (context, i) => _Slide(isi: _slideSambutan[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Jarak.md,
                    Jarak.xs,
                    Jarak.md,
                    Jarak.sm,
                  ),
                  child: Column(
                    children: [
                      TitikHalaman(
                        jumlah: _slideSambutan.length,
                        aktif: _slide,
                      ),
                      const SizedBox(height: Jarak.md),
                      TombolPil(label: 'Mulai', onTekan: _mulai),
                      const SizedBox(height: Jarak.xs2),
                      _TautanMasuk(onTekan: widget.onSudahPunyaAkun),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Isi ketiga slide.
///
/// Gambarnya sengaja bukan ikon di dalam lingkaran, melainkan **benda yang
/// dijanjikan slide itu**: ponsel yang dipakai satu tangan, rak yang menipis,
/// panel laporan.
///
/// Versi sebelumnya memakai replika antarmuka — struk, kartu stok, panel omzet
/// — yang dibangun dari widget layar sungguhan. Niatnya benar, tapi hasilnya
/// terbaca seperti tangkapan layar yang dikecilkan, bukan seperti gambar.
/// Ilustrasi garis punya keleluasaan yang tidak dimiliki replika: ia boleh
/// melebih-lebihkan yang penting dan membuang sisanya.
typedef _IsiSlide = ({String judul, String bawah, GambarIlustrasi gambar});

const _slideSambutan = <_IsiSlide>[
  (
    judul: 'Kasir yang\nmuat di satu\ntangan',
    bawah: 'GESER UNTUK LANJUT',
    gambar: GambarIlustrasi.kasir,
  ),
  (
    judul: 'Catat\npenjualan,\nbukan kertas',
    bawah: 'STOK IKUT TURUN SENDIRI',
    gambar: GambarIlustrasi.rak,
  ),
  (
    judul: 'Laporan dan\nresep ikut\nsekalian',
    bawah: 'TERMASUK DALAM LANGGANAN',
    gambar: GambarIlustrasi.laporan,
  ),
];

class _Slide extends StatelessWidget {
  const _Slide({required this.isi});

  final _IsiSlide isi;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Jarak.md,
        vertical: Jarak.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tinggi tetap supaya carousel tidak melompat tiap kali digeser.
          // Ketiga ilustrasi memakai rasio yang sama, jadi `FittedBox` tidak
          // lagi dibutuhkan untuk menyamakannya — dan karena tidak ada teks di
          // dalam gambar, ukuran huruf sistem tidak bisa membuatnya meluber.
          SizedBox(
            height: 232,
            child: Center(child: Ilustrasi(gambar: isi.gambar)),
          ),
          const SizedBox(height: Jarak.lg),
          Text(isi.judul, style: context.teks.displaySmall),
          const SizedBox(height: Jarak.sm),
          Text(
            isi.bawah,
            style: context.teks.labelSmall?.copyWith(
              color: context.warna.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TautanMasuk extends StatelessWidget {
  const _TautanMasuk({required this.onTekan});

  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Sudah punya akun?',
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: onTekan,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
          ),
          child: const Text('Masuk'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pertanyaan 1 — jenis usaha
// ---------------------------------------------------------------------------

const _jenisUsaha = <(String, IconData)>[
  ('Kafe', Icons.coffee_outlined),
  ('Restoran', Icons.restaurant_outlined),
  ('Warung', Icons.storefront_outlined),
  ('Bakery', Icons.bakery_dining_outlined),
  ('Kelontong', Icons.shopping_basket_outlined),
  ('Lainnya', Icons.more_horiz),
];

class PertanyaanUsahaScreen extends StatefulWidget {
  const PertanyaanUsahaScreen({super.key, required this.onSelesai});

  final VoidCallback onSelesai;

  @override
  State<PertanyaanUsahaScreen> createState() => _PertanyaanUsahaScreenState();
}

class _PertanyaanUsahaScreenState extends State<PertanyaanUsahaScreen> {
  String? _pilihan;

  @override
  Widget build(BuildContext context) {
    return _KerangkaPertanyaan(
      langkah: 1,
      judul: 'Toko Anda\njenisnya apa?',
      keterangan:
          'Kategori dan menu awal disiapkan dari sini. '
          'Bisa diubah kapan saja.',
      labelLanjut: 'Lanjut',
      // Tombol mati sampai ada jawaban. Melewatinya tanpa memilih akan
      // menghasilkan katalog kosong, dan itu kesan pertama yang buruk.
      onLanjut: _pilihan == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    PertanyaanTujuanScreen(onSelesai: widget.onSelesai),
              ),
            ),
      isi: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: Jarak.xs2,
          crossAxisSpacing: Jarak.xs2,
          // Tinggi tetap, bukan rasio: rasio ikut berubah dengan lebar, jadi
          // yang pas di 414 px pasti meluber di 320 px.
          mainAxisExtent: 96,
        ),
        itemCount: _jenisUsaha.length,
        itemBuilder: (context, i) {
          final (label, ikon) = _jenisUsaha[i];
          return _PetakPilihan(
            label: label,
            ikon: ikon,
            terpilih: _pilihan == label,
            onTekan: () => setState(() => _pilihan = label),
          );
        },
      ),
    );
  }
}

class _PetakPilihan extends StatelessWidget {
  const _PetakPilihan({
    required this.label,
    required this.ikon,
    required this.terpilih,
    required this.onTekan,
  });

  final String label;
  final IconData ikon;
  final bool terpilih;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final depan = terpilih ? context.aksen.atasFokus : context.warna.onSurface;

    return Semantics(
      button: true,
      selected: terpilih,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        child: AnimatedContainer(
          duration: Gerak.sedang,
          curve: Gerak.keluar,
          padding: const EdgeInsets.all(Jarak.xs2),
          decoration: BoxDecoration(
            color: terpilih
                ? context.aksen.fokus
                : context.warna.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(Lengkung.kontrol),
            border: Border.all(
              color: terpilih ? context.aksen.fokus : context.warna.outline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikon, size: 26, color: depan),
              const SizedBox(height: Jarak.xs2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.teks.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: depan,
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
// Pertanyaan 2 — keluhan utama
// ---------------------------------------------------------------------------

const _keluhan = <String>[
  'Catatan penjualan berantakan',
  'Stok sering tidak cocok',
  'Tidak tahu untung harian',
  'Struk masih ditulis tangan',
];

class PertanyaanTujuanScreen extends StatefulWidget {
  const PertanyaanTujuanScreen({super.key, required this.onSelesai});

  final VoidCallback onSelesai;

  @override
  State<PertanyaanTujuanScreen> createState() => _PertanyaanTujuanScreenState();
}

class _PertanyaanTujuanScreenState extends State<PertanyaanTujuanScreen> {
  final _terpilih = <String>{};

  @override
  Widget build(BuildContext context) {
    return _KerangkaPertanyaan(
      langkah: 2,
      judul: 'Apa yang paling\ningin dibereskan?',
      keterangan:
          'Boleh lebih dari satu. Yang dipilih akan disorot di Beranda.',
      labelLanjut: 'Selesai',
      onLanjut: _terpilih.isEmpty ? null : widget.onSelesai,
      isi: Column(
        children: [
          for (final k in _keluhan) ...[
            _BarisPilihan(
              label: k,
              terpilih: _terpilih.contains(k),
              onTekan: () => setState(() {
                if (!_terpilih.remove(k)) _terpilih.add(k);
              }),
            ),
            const SizedBox(height: Jarak.xs2),
          ],
        ],
      ),
    );
  }
}

class _BarisPilihan extends StatelessWidget {
  const _BarisPilihan({
    required this.label,
    required this.terpilih,
    required this.onTekan,
  });

  final String label;
  final bool terpilih;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: terpilih,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        child: AnimatedContainer(
          duration: Gerak.sedang,
          curve: Gerak.keluar,
          padding: const EdgeInsets.all(Jarak.sm),
          decoration: BoxDecoration(
            color: context.warna.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(Lengkung.kontrol),
            border: Border.all(
              color: terpilih ? context.warna.onSurface : context.warna.outline,
              width: terpilih ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.teks.bodyLarge?.copyWith(
                    fontWeight: terpilih ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: Jarak.xs2),
              AnimatedOpacity(
                duration: Gerak.sedang,
                opacity: terpilih ? 1 : 0,
                child: Icon(
                  Icons.check_circle,
                  size: 22,
                  color: context.warna.onSurface,
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
// Kerangka bersama dua layar pertanyaan
// ---------------------------------------------------------------------------

class _KerangkaPertanyaan extends StatelessWidget {
  const _KerangkaPertanyaan({
    required this.langkah,
    required this.judul,
    required this.keterangan,
    required this.isi,
    required this.labelLanjut,
    required this.onLanjut,
  });

  final int langkah;
  final String judul;
  final String keterangan;
  final Widget isi;
  final String labelLanjut;
  final VoidCallback? onLanjut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
        ),
      ),
      // Dua layar pertanyaan tidak punya ilustrasi — ruang untuk itu lebih
      // baik dipakai pilihannya sendiri. Tapi kepala halaman yang kosong
      // melompong terbaca seperti layar yang belum selesai memuat, dan motif
      // ini yang memberinya tekstur tanpa menuntut perhatian.
      body: MotifLatar(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  // Penunjuk langkah tinggal di atas, tidak ikut ditengahkan:
                  // ia penanda posisi, dan penanda posisi yang melayang di
                  // tengah layar tidak lagi menandai apa pun.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Jarak.md,
                      Jarak.xs,
                      Jarak.md,
                      0,
                    ),
                    child: PenunjukLangkah(langkah: langkah, dari: 2),
                  ),
                  Expanded(
                    // Isinya ditengahkan secara tegak saat muat, dan menggulir
                    // saat tidak. Versi sebelumnya selalu merapat ke atas, jadi
                    // di ponsel tinggi menyisakan sepertiga layar kosong antara
                    // pilihan terakhir dan tombol — persis kesan "sepi" yang
                    // membuat layar ini terasa belum selesai.
                    child: LayoutBuilder(
                      builder: (context, batas) => SingleChildScrollView(
                        padding: const EdgeInsets.all(Jarak.md),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(
                              0,
                              batas.maxHeight - Jarak.md * 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                judul,
                                textAlign: TextAlign.center,
                                style: context.teks.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: Jarak.xs2),
                              Text(
                                keterangan,
                                textAlign: TextAlign.center,
                                style: context.teks.bodyMedium?.copyWith(
                                  color: context.warna.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: Jarak.md),
                              isi,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Jarak.md,
                      0,
                      Jarak.md,
                      Jarak.sm,
                    ),
                    child: TombolPil(label: labelLanjut, onTekan: onLanjut),
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
