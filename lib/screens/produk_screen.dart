import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../util/simpan_berkas.dart';
import '../widgets/app_shell.dart';
import '../widgets/bingkai.dart';
import '../widgets/blok_foto.dart';
import '../widgets/chip_kategori.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/rangka.dart';
import 'dialog_impor_produk.dart';
import 'form_produk_screen.dart';

/// Master data produk, dikelompokkan per kategori (PRD §1 — "master data
/// kategori/barang").
///
/// Yang bermasalah naik ke atas: satu kartu ringkasan stok sebelum daftar,
/// karena "mana yang habis" adalah satu-satunya pertanyaan yang membuat orang
/// membuka layar ini di tengah jam sibuk.
class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();

  /// Buka formulir produk.
  ///
  /// `produk` null berarti tambah baru. Daftarnya tidak perlu dimuat ulang
  /// setelahnya: `simpanProduk` menaikkan `revisiData`, dan `Bingkai` yang
  /// membungkus layar ini sudah mendengarkannya.
  static Future<void> bukaFormulir(
    BuildContext context, {
    List<Kategori>? kategori,
    Produk? produk,
  }) async {
    // Keadaan kosong memanggil ini sebelum daftar kategori sempat dimuat —
    // di situ ia diambil di sini, bukan dititipkan lewat konstanta dari
    // `contoh.dart` yang justru melanggar kontrak lapisan data.
    final daftar = kategori ?? await Repositori.kategori();
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FormProdukScreen(kategori: daftar, produk: produk),
      ),
    );
  }
}

class _ProdukScreenState extends State<ProdukScreen> {
  /// Kategori yang sedang disaring. Null berarti semua.
  ///
  /// Dipegang DI ATAS [Bingkai], bukan di dalam isinya. Menyimpan produk
  /// menaikkan `revisiData` dan memuat ulang bingkainya — kalau saringan
  /// tinggal di dalam, ia akan balik ke "Semua" setiap kali satu produk
  /// disunting, tepat pada saat orang sedang merapikan satu kategori.
  String? _kategoriId;

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
      saatKosong: Builder(
        builder: (context) {
          final ringkas = MediaQuery.sizeOf(context).width < Ambang.ringkas;
          return ListView(
            padding: padding,
            children: [
              KepalaHalaman(
                judul: 'Produk',
                keterangan: 'Belum ada produk terdaftar.',
                aksi: _BarisAksiProduk(kategori: const [], ringkas: ringkas),
              ),
              const SizedBox(height: Jarak.md),
              Keadaan(
                ikon: Icons.inventory_2_outlined,
                judul: 'Belum Ada Produk',
                keterangan:
                    'Tambahkan produk pertama Anda secara manual atau impor daftar produk secara massal dari berkas Excel (.xlsx).',
                aksiWidget: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Jarak.xs,
                  runSpacing: Jarak.xs,
                  children: [
                    FilledButton.icon(
                      onPressed: () => ProdukScreen.bukaFormulir(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah produk'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => DialogImporProduk.tampilkan(context),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Impor Excel (.xlsx)'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      isi: (context, data) => _Isi(
        kategori: data.$1,
        produk: data.$2,
        // Kategori yang sementara ini disaring bisa saja baru dihapus dari
        // layar Kategori produk. Menahan id yang sudah tidak ada berarti
        // menampilkan daftar kosong tanpa satu pun chip terlihat aktif.
        kategoriId: data.$1.any((k) => k.id == _kategoriId) ? _kategoriId : null,
        onPilihKategori: (id) => setState(() => _kategoriId = id),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({
    required this.kategori,
    required this.produk,
    required this.kategoriId,
    required this.onPilihKategori,
  });

  final List<Kategori> kategori;
  final List<Produk> produk;
  final String? kategoriId;
  final ValueChanged<String?> onPilihKategori;

  bool get _disaring => kategoriId != null;

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);
    final ringkas = MediaQuery.sizeOf(context).width < Ambang.ringkas;

    // Bagian yang ditampilkan mengikuti saringan, dan ringkasan stoknya
    // dihitung dari yang tampil saja. Kartu yang tetap menghitung seluruh
    // toko sementara daftarnya cuma satu kategori adalah kartu yang
    // membantah daftar tepat di bawahnya.
    final terlihat = _disaring
        ? [
            for (final k in kategori)
              if (k.id == kategoriId) k,
          ]
        : kategori;
    final tampil = _disaring
        ? [
            for (final p in produk)
              if (p.kategoriId == kategoriId) p,
          ]
        : produk;

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
              keterangan: _disaring
                  ? '${tampil.length} produk di ${terlihat.isNotEmpty ? terlihat.first.nama : 'kategori'}.'
                  : '${produk.length} produk dalam '
                        '${kategori.length} kategori.',
              aksi: _BarisAksiProduk(kategori: kategori, ringkas: ringkas),
            ),
          ),
        ),

        // Bentuk yang sama persis dengan baris kategori di kasir. Dua layar
        // yang menyaring hal yang sama dengan dua bentuk berbeda memaksa orang
        // mempelajari saringannya dua kali.
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, Jarak.xs),
          sliver: SliverToBoxAdapter(
            child: BarisKategori(
              terpilih: kategoriId,
              onPilih: onPilihKategori,
              item: [
                (null, 'Semua', Icons.grid_view_outlined),
                for (final k in kategori) (k.id, k.nama, k.ikon),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding.left),
          sliver: SliverToBoxAdapter(
            child: _RingkasStok(
              total: tampil.length,
              habis: tampil.where((p) => p.habis).length,
              menipis: tampil.where((p) => p.menipis).length,
            ),
          ),
        ),

        for (final k in terlihat) ...[
          // Judul bagian dilewati saat disaring: chip yang menyala di atas
          // sudah menyebut nama kategorinya, dan mengulanginya di bawah cuma
          // memakan baris yang bisa dipakai produk.
          if (!_disaring)
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
            padding: EdgeInsets.fromLTRB(
              padding.left,
              _disaring ? Jarak.md : 0,
              padding.right,
              0,
            ),
            sliver: SliverToBoxAdapter(
              // Kategori yang baru dibuat belum punya isi. Kartu kosong
              // setinggi satu garis terbaca seperti daftar yang gagal memuat,
              // jadi keadaan kosongnya dikatakan — sekalian dengan jalan
              // keluarnya.
              child: produk.any((p) => p.kategoriId == k.id)
                  ? KartuDaftar(
                      anak: [
                        for (final p in produk.where(
                          (p) => p.kategoriId == k.id,
                        ))
                          _BarisProduk(kategori: kategori, produk: p),
                      ],
                    )
                  : _KategoriKosong(kategori: k, semua: kategori),
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

class _KategoriKosong extends StatelessWidget {
  const _KategoriKosong({required this.kategori, required this.semua});

  final Kategori kategori;
  final List<Kategori> semua;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Jarak.xs,
          vertical: Jarak.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Belum ada produk di ${kategori.nama}.',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Jarak.xs2),
            TextButton(
              onPressed: () =>
                  ProdukScreen.bukaFormulir(context, kategori: semua),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisProduk extends StatelessWidget {
  const _BarisProduk({required this.produk, required this.kategori});

  final Produk produk;
  final List<Kategori> kategori;

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
      onTekan: () => ProdukScreen.bukaFormulir(
        context,
        kategori: kategori,
        produk: produk,
      ),
    );
  }
}

class _BarisAksiProduk extends StatelessWidget {
  const _BarisAksiProduk({
    required this.kategori,
    required this.ringkas,
  });

  final List<Kategori> kategori;
  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: () async {
            try {
              final hasil = await Repositori.eksporProduk();
              await simpanBerkasKePerangkat(hasil.bytes, hasil.filename);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ekspor berhasil: ${hasil.filename}'),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal mengekspor data produk: $e'),
                ),
              );
            }
          },
          icon: const Icon(Icons.download, size: 20),
          tooltip: 'Ekspor Excel (.xlsx)',
        ),
        const SizedBox(width: Jarak.xs2),
        IconButton.outlined(
          onPressed: () => DialogImporProduk.tampilkan(context),
          icon: const Icon(Icons.upload_file, size: 20),
          tooltip: 'Impor Excel (.xlsx)',
        ),
        const SizedBox(width: Jarak.xs2),
        ringkas
            ? IconButton.filled(
                onPressed: () => ProdukScreen.bukaFormulir(
                  context,
                  kategori: kategori,
                ),
                icon: const Icon(Icons.add),
                tooltip: 'Tambah produk',
              )
            : FilledButton.icon(
                onPressed: () => ProdukScreen.bukaFormulir(
                  context,
                  kategori: kategori,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah produk'),
              ),
      ],
    );
  }
}

