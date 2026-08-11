import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../data/sesi_kasir.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/bingkai.dart';
import '../widgets/blok_foto.dart';
import '../widgets/chip_kategori.dart';
import '../widgets/keadaan.dart';
import '../widgets/lembar_buka_kasir.dart';
import '../widgets/rangka.dart';
import '../widgets/tombol_pil.dart';
import 'bayar_screen.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sesi = await Repositori.muatSesiKasirAktif();
      if (sesi == null && mounted) {
        final profil = await Repositori.profil();
        if (mounted) {
          await LembarBukaKasir.tampilkan(context, profilDefault: profil);
        }
      }
    });
  }

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

  int _batas(Produk p) => p.lacakStok ? p.stok : 1 << 31;

  Future<void> _ubah(String id, int delta) async {
    if (delta > 0 && Repositori.sesiKasirAktif.value == null) {
      final profil = await Repositori.profil();
      if (!mounted) return;
      final sesi = await LembarBukaKasir.tampilkan(context, profilDefault: profil);
      if (sesi == null) return;
    }

    setState(() {
      final p = _semua.firstWhere((e) => e.id == id);
      final baru = ((_keranjang[id] ?? 0) + delta).clamp(0, _batas(p));
      if (baru <= 0) {
        _keranjang.remove(id);
      } else {
        _keranjang[id] = baru;
      }
    });
  }

  void _kosongkan() => setState(_keranjang.clear);

  Future<void> _bayar() async {
    final item = _isiKeranjang;
    if (item.isEmpty) return;

    var sesi = Repositori.sesiKasirAktif.value;
    if (sesi == null) {
      final profil = await Repositori.profil();
      if (!mounted) return;
      sesi = await LembarBukaKasir.tampilkan(context, profilDefault: profil);
      if (sesi == null) return;
    }

    if (!mounted) return;
    final hasil = await Navigator.of(context).push<HasilKasir>(
      MaterialPageRoute<HasilKasir>(
        builder: (_) => BayarScreen(
          item: item,
          nomorStruk: Repositori.nomorStrukBerikutnya(),
        ),
      ),
    );
    if (!mounted || hasil == null) return;

    // Daftar produknya sendiri tidak perlu dimuat ulang di sini: menyimpan
    // transaksi menaikkan `revisiData`, dan `Bingkai` yang membungkus layar ini
    // sudah mendengarkannya — termasuk untuk memperbarui stok yang baru turun.
    setState(() {
      _keranjang.clear();
      for (final i in hasil.item) {
        _keranjang[i.produk.id] = i.jumlah;
      }
      // Pembeli berikutnya memulai dari katalog penuh. Saringan yang tertinggal
      // dari pesanan sebelumnya membuat produk pertama yang dicari seolah
      // menghilang.
      if (hasil.selesai) {
        _kendaliCari.clear();
        _cari = '';
        _kategoriId = null;
      }
    });
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

  Future<void> _tanyaKosongkan() async {
    final ya = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ModalKosongkanKeranjang(
        jumlahItem: _jumlahItem,
        total: _total,
      ),
    );
    if ((ya ?? false) && mounted) _kosongkan();
  }

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;
    final duaPanel = lebar >= Ambang.ringkas;

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
        title: ValueListenableBuilder<SesiKasir?>(
          valueListenable: Repositori.sesiKasirAktif,
          builder: (context, sesi, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Kasir'),
                Text(
                  sesi == null
                      ? 'Kasir Belum Dibuka'
                      : 'Kasir: ${sesi.namaKasir} · Omzet: ${rupiah(sesi.totalPenjualan)}',
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        actions: [
          if (_jumlahItem > 0) ...[
            _TombolKosongkan(onTekan: _tanyaKosongkan),
            const SizedBox(width: Jarak.xs2),
          ],
          if (!duaPanel)
            Padding(
              padding: const EdgeInsets.only(right: Jarak.xs),
              child: _TombolKeranjang(
                jumlah: _jumlahItem,
                onTekan: _jumlahItem == 0 ? null : _bukaKeranjang,
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.warna.outline),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<SesiKasir?>(
            valueListenable: Repositori.sesiKasirAktif,
            builder: (context, sesi, _) {
              if (sesi != null) return const SizedBox.shrink();
              return Container(
                color: context.aksen.bahaya.withAlpha(25),
                padding: const EdgeInsets.symmetric(
                  horizontal: Jarak.sm,
                  vertical: Jarak.xs3,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: context.aksen.bahaya,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kasir belum dibuka. Buka kasir untuk memproses transaksi.',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.aksen.bahaya,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: context.aksen.bahaya,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () async {
                        final profil = await Repositori.profil();
                        if (!context.mounted) return;
                        await LembarBukaKasir.tampilkan(
                          context,
                          profilDefault: profil,
                        );
                      },
                      child: const Text('Buka Kasir'),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Bingkai<(List<Kategori>, List<Produk>)>(
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
    ),
  ],
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

/// Kartu produk di katalog kasir.
///
/// **Seluruh kartunya tombol tambah.** Tombol "+" berukuran 34 px di pojok
/// kanan bawah adalah sasaran yang harus dibidik; kartunya sendiri sasaran
/// selebar 230 px yang tidak bisa meleset. Stepper-nya tetap ada — ia yang
/// mengurangi, dan ia yang memperlihatkan berapa yang sudah masuk — tapi ia
/// tidak lagi jadi satu-satunya jalan untuk menambah.
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
    final a = context.aksen;
    final habis = produk.habis;
    final penuh = produk.lacakStok && jumlah >= produk.stok;
    final bolehTambah = !habis && !penuh;
    final terpilih = jumlah > 0;

    return Opacity(
      opacity: habis ? 0.5 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        // Kartu yang sudah masuk keranjang dibingkai tinta. Tanpa penanda
        // setingkat kartu, satu-satunya bukti bahwa ketukan tadi berhasil
        // adalah angka kecil di stepper — dan itu berada di tempat yang justru
        // tertutup jempol saat mengetuk.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Lengkung.panel),
          side: BorderSide(
            color: terpilih ? a.fokus : context.warna.outline,
            width: terpilih ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: bolehTambah ? () => onUbah(1) : null,
          child: Padding(
            padding: const EdgeInsets.all(Jarak.xs2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: BlokFoto(url: produk.gambarUrl)),
                      if (produk.lacakStok)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: _PilStok(produk: produk),
                        ),
                      if (terpilih)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: _LencanaJumlah(jumlah: jumlah),
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
                if (produk.lacakStok) ...[
                  const SizedBox(height: 2),
                  Text(
                    produk.habis
                        ? 'Stok habis'
                        : 'Stok: ${produk.stok} ${produk.satuan}',
                    style: context.teks.labelSmall?.copyWith(
                      color: produk.habis
                          ? a.bahaya
                          : (produk.menipis
                              ? a.peringatan
                              : context.warna.onSurfaceVariant),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
                      if (terpilih) ...[
                        TombolBundar(
                          ikon: jumlah == 1
                              ? Icons.delete_outline
                              : Icons.remove,
                          bahaya: jumlah == 1,
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
                      TombolBundar(
                        ikon: Icons.add,
                        utama: true,
                        onTekan: bolehTambah ? () => onUbah(1) : null,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lencana jumlah di sudut foto — bukti seketika bahwa ketukan tadi masuk.
class _LencanaJumlah extends StatelessWidget {
  const _LencanaJumlah({required this.jumlah});

  final int jumlah;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: a.fokus,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
      ),
      alignment: Alignment.center,
      child: Text(
        '$jumlah',
        style: context.teks.labelMedium?.copyWith(
          color: a.atasFokus,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Tombol Kosongkan — pil bertinta bahaya lembut.
///
/// Berlabel penuh kalau muat, ikon saja kalau tidak: di bawah 380 px,
/// "Kosongkan" + tombol keranjang + judul dua baris sudah saling mendorong.
/// Menyusutkannya jadi ikon lebih baik daripada memotong judulnya jadi "Kasi…".
///
/// Warnanya lembut, bukan merah penuh. Ia aksi merusak yang berdiri permanen di
/// bilah atas selama keranjang terisi — merah pekat di sana akan berteriak
/// sepanjang transaksi, dan yang berteriak terus-menerus akhirnya tidak
/// didengar sama sekali.
class _ModalKosongkanKeranjang extends StatelessWidget {
  const _ModalKosongkanKeranjang({
    required this.jumlahItem,
    required this.total,
  });

  final int jumlahItem;
  final int total;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;

    return Container(
      decoration: BoxDecoration(
        color: context.warna.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Lengkung.panel),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + Jarak.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.warna.outline.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(Jarak.md),
            padding: const EdgeInsets.all(Jarak.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  a.bahayaLembut,
                  context.warna.surfaceContainerHigh,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Lengkung.panel),
              border: Border.all(color: a.bahaya.withAlpha(60)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: a.bahaya,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: a.bahaya.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Jarak.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kosongkan Keranjang?',
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: a.bahaya,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$jumlahItem item (${rupiah(total)}) akan dihapus dari daftar pesanan.',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Jarak.md),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: BorderSide(color: context.warna.outline),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                ),
                const SizedBox(width: Jarak.xs),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: a.bahaya,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Ya, Kosongkan'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TombolKosongkan extends StatelessWidget {
  const _TombolKosongkan({required this.onTekan});

  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;

    return Tooltip(
      message: 'Kosongkan keranjang',
      child: Material(
        color: a.bahaya.withAlpha(20),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTekan,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: a.bahaya.withAlpha(70)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.delete_sweep_rounded,
              size: 20,
              color: a.bahaya,
            ),
          ),
        ),
      ),
    );
  }
}

class _TombolKeranjang extends StatelessWidget {
  const _TombolKeranjang({required this.jumlah, required this.onTekan});

  final int jumlah;
  final VoidCallback? onTekan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final terisi = jumlah > 0;

    return Tooltip(
      message: terisi ? 'Lihat keranjang · $jumlah item' : 'Keranjang kosong',
      child: Material(
        color: terisi ? context.warna.primaryContainer : context.warna.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTekan,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: terisi ? context.warna.primary.withAlpha(80) : context.warna.outline,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  size: 20,
                  color: terisi
                      ? context.warna.primary
                      : context.warna.onSurfaceVariant,
                ),
                if (terisi)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: a.sukses,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$jumlah',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _PilStok extends StatelessWidget {
  const _PilStok({required this.produk});

  final Produk produk;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final habis = produk.habis;
    final menipis = produk.menipis;

    final Color color;
    final Color textColor;
    final String text;

    if (habis) {
      color = a.bahayaLembut;
      textColor = a.bahaya;
      text = 'Habis';
    } else if (menipis) {
      color = a.peringatanLembut;
      textColor = a.peringatan;
      text = 'Sisa ${produk.stok}';
    } else {
      color = context.warna.surfaceContainerHighest.withAlpha(220);
      textColor = context.warna.onSurfaceVariant;
      text = 'Stok ${produk.stok}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
        border: Border.all(
          color: habis
              ? a.bahaya.withAlpha(80)
              : (menipis
                  ? a.peringatan.withAlpha(80)
                  : context.warna.outline.withAlpha(120)),
        ),
      ),
      child: Text(
        text,
        style: context.teks.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Keranjang
// ---------------------------------------------------------------------------

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

    return Container(
      decoration: BoxDecoration(
        color: context.warna.primaryContainer,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        border: Border.all(
          color: context.warna.primary.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: context.warna.primary.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        child: InkWell(
          onTap: onBuka,
          borderRadius: BorderRadius.circular(Lengkung.panel),
          child: Padding(
            padding: const EdgeInsets.all(Jarak.xs),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.warna.primary,
                    borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_rounded,
                        color: context.warna.onPrimary,
                        size: 22,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: a.sukses,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$jumlahItem',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Jarak.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rupiah(total),
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.warna.onPrimaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$jumlahItem item · $ringkasan',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onPrimaryContainer.withAlpha(180),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Jarak.xs),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: onBayar,
                    style: FilledButton.styleFrom(
                      backgroundColor: a.sukses,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Bayar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
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
                      'Ketuk kartu produk untuk menambahkan.',
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
                child: Text('Keranjang Belanja', style: context.teks.titleLarge),
              ),
              TextButton.icon(
                onPressed: onKosongkan,
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Kosongkan'),
                style: TextButton.styleFrom(
                  foregroundColor: context.aksen.bahaya,
                ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(Jarak.xs2),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline.withAlpha(80)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: BlokFoto(url: item.produk.gambarUrl, tampilkanLabel: false),
            ),
          ),
          const SizedBox(width: Jarak.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.produk.nama,
                  style: context.teks.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${rupiah(item.produk.hargaJual)} x ${item.jumlah}',
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
          const SizedBox(width: Jarak.xs2),
          Text(
            rupiah(item.subtotal),
            style: context.teks.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.warna.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: Jarak.xs2),
          TombolBundar(
            ikon: item.jumlah == 1 ? Icons.delete_outline : Icons.remove,
            bahaya: item.jumlah == 1,
            onTekan: () => onUbah(item.produk.id, -1),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${item.jumlah}',
              textAlign: TextAlign.center,
              style: context.teks.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TombolBundar(
            ikon: Icons.add,
            utama: true,
            onTekan: item.produk.lacakStok && item.jumlah >= item.produk.stok
                ? null
                : () => onUbah(item.produk.id, 1),
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
    final a = context.aksen;

    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.warna.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                    'Total Pembayaran',
                    style: context.teks.bodyMedium?.copyWith(
                      color: context.warna.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    rupiah(total),
                    style: context.teks.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.warna.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Jarak.md),
            Row(
              children: [
                if (!tanpaKosongkan) ...[
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: OutlinedButton(
                      onPressed: onKosongkan,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: a.bahaya,
                        side: BorderSide(color: a.bahaya.withAlpha(100)),
                        shape: const StadiumBorder(),
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        size: 22,
                        color: a.bahaya,
                      ),
                    ),
                  ),
                  const SizedBox(width: Jarak.xs),
                ],
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: onBayar,
                      style: FilledButton.styleFrom(
                        backgroundColor: a.sukses,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 3,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 20),
                      label: const Text('Proses Pembayaran'),
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
