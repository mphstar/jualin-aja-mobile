import 'package:flutter/material.dart';

import '../data/contoh.dart';
import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import 'bayar_screen.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/bingkai.dart';
import '../widgets/blok_foto.dart';
import '../widgets/chip_kategori.dart';
import '../widgets/keadaan.dart';
import '../widgets/rangka.dart';

/// Layar kasir. Mode layar penuh, bukan tab.
///
/// Empat gerakan yang membuatnya bekerja:
///
///   1. kartu produk didominasi blok visual, bukan teks
///   2. kategori berupa lingkaran berikon 56 px, bukan chip teks ~32 px
///   3. stepper +/− langsung di kartu — menambah kuantitas tidak boleh
///      menuntut membuka keranjang lebih dulu
///   4. bilah keranjang tinta mengambang, selalu terlihat begitu ada isi
///
/// Ketiga dan keempat yang paling menentukan kecepatan sungguhan: tanpa
/// keduanya, satu pesanan tiga item butuh enam ketukan dan dua kali buka-tutup
/// panel.
class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _keranjang = <String, int>{};
  final _kendaliCari = TextEditingController();
  String? _kategoriId;
  String _cari = '';

  List<Produk> _semua = const [];
  List<Kategori> _kategori = const [];

  @override
  void dispose() {
    _kendaliCari.dispose();
    super.dispose();
  }

  List<Produk> get _terlihat {
    final kunci = _cari.trim().toLowerCase();
    return _semua.where((p) {
      if (_kategoriId != null && p.kategoriId != _kategoriId) return false;
      if (kunci.isEmpty) return true;
      return p.nama.toLowerCase().contains(kunci);
    }).toList();
  }

  List<ItemKeranjang> get _isiKeranjang => [
    for (final e in _keranjang.entries)
      ItemKeranjang(
        produk: _semua.firstWhere((p) => p.id == e.key),
        jumlah: e.value,
      ),
  ];

  int get _total => _isiKeranjang.fold(0, (n, i) => n + i.subtotal);
  int get _jumlahItem => _keranjang.values.fold(0, (n, j) => n + j);

  void _ubah(String id, int delta) {
    setState(() {
      final baru = (_keranjang[id] ?? 0) + delta;
      if (baru <= 0) {
        _keranjang.remove(id);
      } else {
        _keranjang[id] = baru;
      }
    });
  }

  void _kosongkan() => setState(_keranjang.clear);

  /// Buka layar pembayaran.
  ///
  /// Keranjang baru dikosongkan SETELAH layar itu selesai dan transaksinya
  /// benar-benar tersimpan — kalau dikosongkan lebih dulu, kasir yang menekan
  /// batal atau kehilangan koneksi akan kehilangan seluruh pesanannya.
  Future<void> _bayar() async {
    final item = _isiKeranjang;
    if (item.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BayarScreen(
          item: item,
          nomorStruk: Repositori.nomorStrukBerikutnya(),
        ),
      ),
    );
    if (!mounted) return;

    // Transaksi tersimpan kalau daftar transaksi bertambah; layar bayar sendiri
    // tidak perlu melaporkan apa pun kembali ke sini.
    final tersimpan =
        transaksiContoh.isNotEmpty &&
        transaksiContoh.first.nomorStruk != _strukSaatMasuk;
    // Daftar produknya sendiri tidak perlu dimuat ulang di sini: menyimpan
    // transaksi menaikkan `revisiData`, dan `Bingkai` yang membungkus layar ini
    // sudah mendengarkannya — termasuk untuk memperbarui stok yang baru turun.
    if (tersimpan) _kosongkan();
  }

  void _bukaKeranjang() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, kendali) => _IsiKeranjang(
          item: _isiKeranjang,
          total: _total,
          kendali: kendali,
          onUbah: (id, d) {
            _ubah(id, d);
            if (_keranjang.isEmpty) Navigator.of(context).pop();
          },
          onKosongkan: () {
            _kosongkan();
            Navigator.of(context).pop();
          },
          onBayar: () {
            Navigator.of(context).pop();
            _bayar();
          },
        ),
      ),
    );
  }

  /// Nomor struk yang akan dipakai transaksi ini — dihitung Repositori dari
  /// struk terakhir, bukan dikarang di layar.
  String get _strukBerikutnya => Repositori.nomorStrukBerikutnya();

  /// Nomor struk terakhir saat layar bayar dibuka, untuk mengetahui apakah
  /// transaksinya jadi tersimpan.
  String get _strukSaatMasuk =>
      transaksiContoh.isEmpty ? '' : transaksiContoh.first.nomorStruk;

  Future<void> _tanyaKosongkan() async {
    // Mengosongkan keranjang membuang pekerjaan yang tidak bisa dikembalikan,
    // dan tombolnya duduk tepat di sebelah tombol tutup. Satu ketukan salah
    // tidak boleh menghapus pesanan yang sudah setengah jalan.
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: Text(
          '$_jumlahItem item akan dihapus. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.aksen.bahaya,
              foregroundColor: context.warna.onError,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if ((ya ?? false) && mounted) _kosongkan();
  }

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;
    final duaPanel = lebar >= Ambang.ringkas;
    final ringkas = lebar < 380;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
          tooltip: 'Tutup kasir',
        ),
        titleSpacing: 0,
        // Dua baris: layar apa ini, dan struk mana yang sedang disusun. Nomor
        // struk berikutnya tidak muncul di tempat lain mana pun, jadi ia
        // menambah keterangan alih-alih mengulang bilah keranjang di bawah.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kasir'),
            Text(
              _strukBerikutnya,
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_jumlahItem > 0)
            _TombolKosongkan(ringkas: ringkas, onTekan: _tanyaKosongkan),
          // Keranjang butuh jalan masuk yang selalu di tempat yang sama.
          // Sebelum ini satu-satunya cara membukanya adalah mengetuk bilah
          // mengambang — yang justru tidak ada saat keranjang masih kosong,
          // jadi tidak pernah ada tempat untuk belajar bahwa ia bisa dibuka.
          if (!duaPanel)
            Padding(
              padding: const EdgeInsets.only(right: Jarak.xs2),
              child: Badge(
                isLabelVisible: _jumlahItem > 0,
                label: Text('$_jumlahItem'),
                backgroundColor: context.aksen.fokus,
                textColor: context.aksen.atasFokus,
                child: IconButton.filledTonal(
                  onPressed: _jumlahItem == 0 ? null : _bukaKeranjang,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Lihat keranjang',
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.warna.outline),
        ),
      ),
      body: Bingkai<(List<Kategori>, List<Produk>)>(
        ambil: () async {
          final k = await Repositori.kategori();
          final p = await Repositori.produk();
          return (k, p);
        },
        rangka: Padding(
          padding: const EdgeInsets.all(Jarak.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Rangka(tinggi: 48, radius: Lengkung.kontrol),
              SizedBox(height: Jarak.sm),
              Rangka(tinggi: 56, radius: Lengkung.kontrol),
              SizedBox(height: Jarak.sm),
              Expanded(child: RangkaPetak()),
            ],
          ),
        ),
        kosong: (d) => d.$2.isEmpty,
        saatKosong: Padding(
          padding: const EdgeInsets.all(Jarak.sm),
          child: Keadaan(
            ikon: Icons.inventory_2_outlined,
            judul: 'Belum ada produk',
            keterangan:
                'Kasir butuh setidaknya satu produk sebelum bisa dipakai. '
                'Tambahkan dari menu Produk.',
            labelAksi: 'Tutup kasir',
            onAksi: () => Navigator.of(context).maybePop(),
          ),
        ),
        isi: (context, data) {
          // Disimpan supaya `_terlihat` dan `_isiKeranjang` bisa membacanya
          // tanpa harus meneruskan daftar produk lewat lima lapis widget.
          _kategori = data.$1;
          _semua = data.$2;

          final katalog = _Katalog(
            kategori: _kategori,
            kategoriId: _kategoriId,
            kendaliCari: _kendaliCari,
            produk: _terlihat,
            keranjang: _keranjang,
            ruangBawah: duaPanel ? 0 : 96,
            onPilihKategori: (id) => setState(() => _kategoriId = id),
            onCari: (v) => setState(() => _cari = v),
            onUbah: _ubah,
          );

          if (duaPanel) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: katalog),
                VerticalDivider(width: 1, color: context.warna.outline),
                SizedBox(
                  width: 320,
                  child: _PanelKeranjang(
                    item: _isiKeranjang,
                    total: _total,
                    onUbah: _ubah,
                    onKosongkan: _kosongkan,
                    onBayar: _bayar,
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: katalog),
              if (_jumlahItem > 0)
                Positioned(
                  left: Jarak.sm,
                  right: Jarak.sm,
                  bottom: Jarak.sm,
                  child: SafeArea(
                    top: false,
                    child: BilahKeranjang(
                      jumlahItem: _jumlahItem,
                      total: _total,
                      ringkasan: _isiKeranjang
                          .map((i) => i.produk.nama)
                          .join(', '),
                      onBuka: _bukaKeranjang,
                      onBayar: _bayar,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Katalog
// ---------------------------------------------------------------------------

class _Katalog extends StatelessWidget {
  const _Katalog({
    required this.kategori,
    required this.kategoriId,
    required this.kendaliCari,
    required this.produk,
    required this.keranjang,
    required this.ruangBawah,
    required this.onPilihKategori,
    required this.onCari,
    required this.onUbah,
  });

  final List<Kategori> kategori;
  final String? kategoriId;
  final TextEditingController kendaliCari;
  final List<Produk> produk;
  final Map<String, int> keranjang;
  final double ruangBawah;
  final ValueChanged<String?> onPilihKategori;
  final ValueChanged<String> onCari;
  final void Function(String, int) onUbah;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, Jarak.xs2, Jarak.sm, 0),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: kendaliCari,
              onChanged: onCari,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari produk',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: kendaliCari.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          kendaliCari.clear();
                          onCari('');
                        },
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Hapus pencarian',
                      ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, Jarak.xs, Jarak.sm, 0),
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
        if (produk.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(Jarak.sm),
            sliver: const SliverToBoxAdapter(
              child: Keadaan(
                ikon: Icons.search_off,
                judul: 'Tidak ada yang cocok',
                keterangan:
                    'Coba kata kunci lain, atau pilih kategori "Semua" '
                    'untuk melihat seluruh produk.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Jarak.sm,
              Jarak.xs2,
              Jarak.sm,
              Jarak.sm + ruangBawah,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisSpacing: Jarak.xs,
                crossAxisSpacing: Jarak.xs,
                mainAxisExtent: 238,
              ),
              itemCount: produk.length,
              itemBuilder: (context, i) {
                final p = produk[i];
                return _KartuProduk(
                  produk: p,
                  jumlah: keranjang[p.id] ?? 0,
                  onUbah: (d) => onUbah(p.id, d),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _KartuProduk extends StatelessWidget {
  const _KartuProduk({
    required this.produk,
    required this.jumlah,
    required this.onUbah,
  });

  final Produk produk;
  final int jumlah;
  final ValueChanged<int> onUbah;

  @override
  Widget build(BuildContext context) {
    final habis = produk.habis;

    return Opacity(
      opacity: habis ? 0.5 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Jarak.xs2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: BlokFoto(url: produk.gambarUrl)),
                    if (produk.menipis || habis)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: _Pil(
                          teks: habis ? 'Habis' : 'Sisa ${produk.stok}',
                          bahaya: habis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Jarak.xs2),
              Text(
                produk.nama,
                style: context.teks.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Jarak.xs3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rupiah(produk.hargaJual),
                      style: context.teks.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!habis) ...[
                    if (jumlah > 0) ...[
                      _TombolBundar(
                        ikon: Icons.remove,
                        onTekan: () => onUbah(-1),
                      ),
                      SizedBox(
                        width: 26,
                        child: Text(
                          '$jumlah',
                          textAlign: TextAlign.center,
                          style: context.teks.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    _TombolBundar(
                      ikon: Icons.add,
                      utama: true,
                      onTekan: () => onUbah(1),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol Kosongkan. Berlabel penuh kalau muat, ikon saja kalau tidak.
///
/// Di bawah 380 px, "Kosongkan" + tombol keranjang + judul dua baris sudah
/// saling mendorong. Menyusutkannya jadi ikon lebih baik daripada memotong
/// judulnya jadi "Kasi…".
class _TombolKosongkan extends StatelessWidget {
  const _TombolKosongkan({required this.ringkas, required this.onTekan});

  final bool ringkas;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    if (ringkas) {
      return IconButton(
        onPressed: onTekan,
        icon: const Icon(Icons.remove_shopping_cart_outlined),
        tooltip: 'Kosongkan keranjang',
        color: context.aksen.bahaya,
      );
    }
    return TextButton.icon(
      onPressed: onTekan,
      icon: const Icon(Icons.remove_shopping_cart_outlined, size: 18),
      label: const Text('Kosongkan'),
      style: TextButton.styleFrom(
        foregroundColor: context.aksen.bahaya,
        padding: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
      ),
    );
  }
}

class _Pil extends StatelessWidget {
  const _Pil({required this.teks, required this.bahaya});

  final String teks;
  final bool bahaya;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bahaya ? a.bahayaLembut : a.peringatanLembut,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
      ),
      child: Text(
        teks,
        style: context.teks.labelSmall?.copyWith(
          color: bahaya ? a.bahaya : a.peringatan,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _TombolBundar extends StatelessWidget {
  const _TombolBundar({
    required this.ikon,
    required this.onTekan,
    this.utama = false,
  });

  final IconData ikon;
  final VoidCallback onTekan;
  final bool utama;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTekan,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: utama ? a.fokus : context.warna.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: utama ? a.fokus : context.warna.outline),
          ),
          alignment: Alignment.center,
          child: Icon(
            ikon,
            size: 18,
            color: utama ? a.atasFokus : context.warna.onSurface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Keranjang
// ---------------------------------------------------------------------------

/// Bilah tinta mengambang. Selalu terlihat begitu keranjang ada isinya.
class BilahKeranjang extends StatelessWidget {
  const BilahKeranjang({
    super.key,
    required this.jumlahItem,
    required this.total,
    required this.ringkasan,
    required this.onBuka,
    required this.onBayar,
  });

  final int jumlahItem;
  final int total;
  final String ringkasan;
  final VoidCallback onBuka;
  final VoidCallback onBayar;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Material(
      color: a.fokus,
      borderRadius: BorderRadius.circular(Lengkung.kontrol),
      child: InkWell(
        onTap: onBuka,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        child: Container(
          padding: const EdgeInsets.all(Jarak.xs2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Lengkung.kontrol),
            boxShadow: a.bayanganMengambang,
          ),
          child: Row(
            children: [
              const SizedBox(width: Jarak.xs3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$jumlahItem item · ${rupiah(total)}',
                      style: context.teks.titleSmall?.copyWith(
                        color: a.atasFokus,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ringkasan,
                      style: context.teks.bodySmall?.copyWith(
                        color: a.atasFokusRedup,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Jarak.xs2),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: onBayar,
                  style: FilledButton.styleFrom(
                    backgroundColor: a.atasFokus,
                    foregroundColor: a.fokus,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
                  ),
                  child: const Text('Bayar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel keranjang tetap untuk layar ≥ 600 px.
class _PanelKeranjang extends StatelessWidget {
  const _PanelKeranjang({
    required this.item,
    required this.total,
    required this.onUbah,
    required this.onKosongkan,
    required this.onBayar,
  });

  final List<ItemKeranjang> item;
  final int total;
  final void Function(String, int) onUbah;
  final VoidCallback onKosongkan;
  final VoidCallback onBayar;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.warna.surfaceContainerLowest,
      child: item.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Jarak.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 32,
                      color: context.warna.onSurfaceVariant,
                    ),
                    const SizedBox(height: Jarak.xs2),
                    Text(
                      'Keranjang kosong',
                      style: context.teks.titleSmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk + pada produk untuk menambahkan.',
                      textAlign: TextAlign.center,
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(Jarak.xs),
                    children: [
                      for (final i in item)
                        _BarisKeranjang(item: i, onUbah: onUbah),
                    ],
                  ),
                ),
                _KakiKeranjang(
                  total: total,
                  onKosongkan: onKosongkan,
                  onBayar: onBayar,
                ),
              ],
            ),
    );
  }
}

class _IsiKeranjang extends StatelessWidget {
  const _IsiKeranjang({
    required this.item,
    required this.total,
    required this.kendali,
    required this.onUbah,
    required this.onKosongkan,
    required this.onBayar,
  });

  final List<ItemKeranjang> item;
  final int total;
  final ScrollController kendali;
  final void Function(String, int) onUbah;
  final VoidCallback onKosongkan;
  final VoidCallback onBayar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
          child: Row(
            children: [
              Expanded(
                child: Text('Keranjang', style: context.teks.titleLarge),
              ),
              TextButton(
                onPressed: onKosongkan,
                child: const Text('Kosongkan'),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xs2),
        Expanded(
          child: ListView(
            controller: kendali,
            padding: const EdgeInsets.symmetric(horizontal: Jarak.xs),
            children: [
              for (final i in item) _BarisKeranjang(item: i, onUbah: onUbah),
            ],
          ),
        ),
        _KakiKeranjang(
          total: total,
          onKosongkan: onKosongkan,
          onBayar: onBayar,
          tanpaKosongkan: true,
        ),
      ],
    );
  }
}

class _BarisKeranjang extends StatelessWidget {
  const _BarisKeranjang({required this.item, required this.onUbah});

  final ItemKeranjang item;
  final void Function(String, int) onUbah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Jarak.xs3),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: BlokFoto(url: item.produk.gambarUrl, tampilkanLabel: false),
          ),
          const SizedBox(width: Jarak.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.produk.nama,
                  style: context.teks.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${rupiah(item.produk.hargaJual)} · ${rupiah(item.subtotal)}',
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Jarak.xs2),
          _TombolBundar(
            ikon: item.jumlah == 1 ? Icons.delete_outline : Icons.remove,
            onTekan: () => onUbah(item.produk.id, -1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.jumlah}',
              textAlign: TextAlign.center,
              style: context.teks.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _TombolBundar(
            ikon: Icons.add,
            utama: true,
            onTekan: () => onUbah(item.produk.id, 1),
          ),
        ],
      ),
    );
  }
}

class _KakiKeranjang extends StatelessWidget {
  const _KakiKeranjang({
    required this.total,
    required this.onKosongkan,
    required this.onBayar,
    this.tanpaKosongkan = false,
  });

  final int total;
  final VoidCallback onKosongkan;
  final VoidCallback onBayar;
  final bool tanpaKosongkan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.sm),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.warna.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: context.teks.bodyMedium?.copyWith(
                      color: context.warna.onSurfaceVariant,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    rupiah(total),
                    style: context.teks.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Jarak.xs),
            Row(
              children: [
                if (!tanpaKosongkan) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onKosongkan,
                      child: const Text('Kosongkan'),
                    ),
                  ),
                  const SizedBox(width: Jarak.xs2),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onBayar,
                    child: const Text('Bayar'),
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
