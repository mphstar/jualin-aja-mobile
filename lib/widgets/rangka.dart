import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Blok rangka untuk keadaan memuat.
///
/// Bukan pemintal di tengah layar. Rangka yang berbentuk seperti isi yang
/// akan datang membuat tata letak tidak melompat saat data tiba — dan
/// lompatan itulah yang sebenarnya terasa lambat, bukan detiknya.
///
/// Denyutnya halus (opasitas 1 → 0.45) dan berhenti total saat pengguna
/// meminta gerak dikurangi.
class Rangka extends StatefulWidget {
  const Rangka({
    super.key,
    this.lebar,
    this.tinggi = 14,
    this.radius = Lengkung.kecil,
  });

  /// Null berarti selebar induknya.
  final double? lebar;
  final double tinggi;
  final double radius;

  @override
  State<Rangka> createState() => _RangkaState();
}

class _RangkaState extends State<Rangka> with SingleTickerProviderStateMixin {
  late final AnimationController _kendali = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _kendali.repeat(reverse: true);
  }

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kotak = Container(
      width: widget.lebar,
      height: widget.tinggi,
      decoration: BoxDecoration(
        color: context.aksen.isian,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return kotak;

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.45).animate(_kendali),
      child: kotak,
    );
  }
}

/// Rangka berbentuk daftar baris — dipakai Produk, Riwayat, dan Resep.
class RangkaDaftar extends StatelessWidget {
  const RangkaDaftar({super.key, this.baris = 5, this.tinggiBaris = 64});

  final int baris;
  final double tinggiBaris;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < baris; i++) ...[
            if (i > 0) Divider(height: 1, color: context.warna.outline),
            SizedBox(
              height: tinggiBaris,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
                child: Row(
                  children: [
                    const Rangka(lebar: 40, tinggi: 40),
                    const SizedBox(width: Jarak.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lebar baris sengaja berselang-seling supaya
                          // rangkanya terbaca sebagai teks, bukan sebagai
                          // tabel kosong.
                          Rangka(lebar: i.isEven ? 150 : 116, tinggi: 12),
                          const SizedBox(height: 6),
                          const Rangka(lebar: 78, tinggi: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: Jarak.xs2),
                    const Rangka(lebar: 56, tinggi: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rangka berbentuk petak — dipakai grid produk di Kasir.
class RangkaPetak extends StatelessWidget {
  const RangkaPetak({super.key, this.jumlah = 6});

  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisSpacing: Jarak.xs,
        crossAxisSpacing: Jarak.xs,
        mainAxisExtent: 238,
      ),
      itemCount: jumlah,
      itemBuilder: (context, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(Jarak.xs2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Rangka(tinggi: double.infinity, radius: Lengkung.kecil),
              ),
              const SizedBox(height: Jarak.xs2),
              const Rangka(tinggi: 12),
              const SizedBox(height: 6),
              const Rangka(lebar: 70, tinggi: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rangka berbentuk kartu tunggal — dipakai Beranda dan Laporan.
class RangkaPanel extends StatelessWidget {
  const RangkaPanel({super.key, this.tinggi = 148});

  final double tinggi;

  @override
  Widget build(BuildContext context) {
    // Isi rangka menyesuaikan tinggi yang tersedia. Panel pendek hanya memuat
    // dua baris; memaksakan tiga akan meluber — dan rangka yang meluber adalah
    // bug yang muncul persis di detik pertama layar dibuka, tiap kali.
    final ruang = tinggi - Jarak.md * 2 - 2;
    final lega = ruang >= 66;

    return Container(
      height: tinggi,
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        border: Border.all(color: context.warna.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lega
            ? const [
                Rangka(lebar: 120, tinggi: 12),
                SizedBox(height: Jarak.xs),
                Rangka(lebar: 190, tinggi: 30),
                Spacer(),
                Rangka(tinggi: 12),
              ]
            : const [
                Rangka(lebar: 100, tinggi: 10),
                SizedBox(height: Jarak.xs2),
                Rangka(lebar: 160, tinggi: 22),
              ],
      ),
    );
  }
}
