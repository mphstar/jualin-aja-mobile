import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/app_shell.dart';
import '../widgets/bingkai.dart';
import '../widgets/blok_foto.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/rangka.dart';

/// Master data produk, dikelompokkan per kategori (PRD §1 — "master data
/// kategori/barang").
///
/// Yang bermasalah naik ke atas: satu kartu ringkasan stok sebelum daftar,
/// karena "mana yang habis" adalah satu-satunya pertanyaan yang membuat orang
/// membuka layar ini di tengah jam sibuk.
class ProdukScreen extends StatelessWidget {
  const ProdukScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return Bingkai<(List<Kategori>, List<Produk>)>(
      ambil: () async {
        final k = await Repositori.kategori();
        final p = await Repositori.produk();
        return (k, p);
      },
      rangka: ListView(
        padding: padding,
        children: const [
          KepalaHalaman(judul: 'Produk'),
          RangkaPanel(tinggi: 92),
          SizedBox(height: Jarak.md),
          RangkaDaftar(),
        ],
      ),
      kosong: (d) => d.$2.isEmpty,
      saatKosong: ListView(
        padding: padding,
        children: [
          const KepalaHalaman(judul: 'Produk'),
          Keadaan(
            ikon: Icons.inventory_2_outlined,
            judul: 'Belum ada produk',
            keterangan:
                'Tambahkan produk pertama Anda — nama, harga, dan satuan '
                'sudah cukup untuk mulai berjualan.',
            labelAksi: 'Tambah produk',
            onAksi: () => _menyusul(context),
          ),
        ],
      ),
      isi: (context, data) => _Isi(kategori: data.$1, produk: data.$2),
    );
  }

  static void _menyusul(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Formulir produk menyusul.')),
      );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.kategori, required this.produk});

  final List<Kategori> kategori;
  final List<Produk> produk;

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);
    final ringkas = MediaQuery.sizeOf(context).width < Ambang.ringkas;
    final habis = produk.where((p) => p.habis).length;
    final menipis = produk.where((p) => p.menipis).length;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: KepalaHalaman(
              judul: 'Produk',
              keterangan:
                  '${produk.length} produk dalam ${kategori.length} kategori.',
              aksi: ringkas
                  ? IconButton.filled(
                      onPressed: () => ProdukScreen._menyusul(context),
                      icon: const Icon(Icons.add),
                      tooltip: 'Tambah produk',
                    )
                  : FilledButton.icon(
                      onPressed: () => ProdukScreen._menyusul(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah produk'),
                    ),
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding.left),
          sliver: SliverToBoxAdapter(
            child: _RingkasStok(
              total: produk.length,
              habis: habis,
              menipis: menipis,
            ),
          ),
        ),

        for (final k in kategori) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              Jarak.md,
              padding.right,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _JudulKategori(
                kategori: k,
                jumlah: produk.where((p) => p.kategoriId == k.id).length,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding.left),
            sliver: SliverToBoxAdapter(
              child: KartuDaftar(
                anak: [
                  for (final p in produk.where((p) => p.kategoriId == k.id))
                    _BarisProduk(produk: p),
                ],
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: padding.bottom)),
      ],
    );
  }
}

class _RingkasStok extends StatelessWidget {
  const _RingkasStok({
    required this.total,
    required this.habis,
    required this.menipis,
  });

  final int total;
  final int habis;
  final int menipis;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Jarak.sm,
          vertical: Jarak.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: _Angka(label: 'Total', nilai: '$total'),
            ),
            _Pemisah(),
            Expanded(
              child: _Angka(
                label: 'Menipis',
                nilai: '$menipis',
                warna: menipis > 0 ? a.peringatan : null,
              ),
            ),
            _Pemisah(),
            Expanded(
              child: _Angka(
                label: 'Habis',
                nilai: '$habis',
                warna: habis > 0 ? a.bahaya : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pemisah extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
    color: context.warna.outline,
  );
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
        Text(
          nilai,
          style: context.teks.titleLarge?.copyWith(
            color: warna,
            fontFeatures: const [FontFeature.tabularFigures()],
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

class _JudulKategori extends StatelessWidget {
  const _JudulKategori({required this.kategori, required this.jumlah});

  final Kategori kategori;
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return JudulBagian(
      '${kategori.nama} · $jumlah',
      aksi: Icon(
        kategori.ikon,
        size: 16,
        color: context.warna.onSurfaceVariant,
      ),
    );
  }
}

class _BarisProduk extends StatelessWidget {
  const _BarisProduk({required this.produk});

  final Produk produk;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final (teksStok, warnaStok) = !produk.lacakStok
        ? ('Stok tidak dilacak', null)
        : produk.habis
        ? ('Habis', a.bahaya)
        : produk.menipis
        ? ('Sisa ${produk.stok} ${produk.satuan}', a.peringatan)
        : ('Stok ${produk.stok} ${produk.satuan}', null);

    return BarisDaftar(
      // Petak foto, bukan ikon kardus generik: layar ini justru tempat pemilik
      // toko nanti mengunggah fotonya, jadi tempatnya sudah disiapkan dan
      // terbaca sebagai "belum diisi".
      awalan: SizedBox(
        width: 44,
        height: 44,
        child: BlokFoto(url: produk.gambarUrl, tampilkanLabel: false),
      ),
      judul: produk.nama,
      keterangan: teksStok,
      warnaKeterangan: warnaStok,
      akhiran: rupiah(produk.hargaJual),
      onTekan: () => ProdukScreen._menyusul(context),
    );
  }
}
