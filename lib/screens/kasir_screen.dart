import 'package:flutter/material.dart';

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
import '../widgets/tombol_pil.dart';

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

  /// Jumlah maksimum yang boleh masuk keranjang.
  ///
  /// Produk tanpa pelacakan stok tidak punya batas — itu memang artinya tidak
  /// dilacak. Yang dilacak berhenti di sisanya: keranjang berisi 8 sementara
  /// raknya berisi 3 adalah janji yang tidak bisa ditepati, dan baru ketahuan
  /// saat pembeli sudah membayar.
  int _batas(Produk p) => p.lacakStok ? p.stok : 1 << 31;

  void _ubah(String id, int delta) {
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

  /// Buka layar pembayaran, lalu **selalu** samakan keranjang dengan apa yang
  /// dibawa kembali layar itu.
  ///
  /// Dua keadaan, satu jalan pulang. Transaksi yang tersimpan mengembalikan
  /// pesanan kosong sehingga keranjang ikut kosong; yang dibatalkan
  /// mengembalikan pesanan apa adanya — termasuk baris yang barusan ditambah
  /// atau dihapus di layar bayar. Yang dulu dilakukan di sini — menebak dari
  /// nomor struk terakhir apakah transaksinya jadi — tidak pernah bisa benar:
  /// nomornya dibaca setelah layar bayar menutup diri, jadi ia selalu
  /// dibandingkan dengan dirinya sendiri.
  Future<void> _bayar() async {
    final item = _isiKeranjang;
    if (item.isEmpty) return;

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

  /// Nomor struk yang akan dipakai transaksi ini — dihitung Repositori dari
  /// struk terakhir, bukan dikarang di layar.
  String get _strukBerikutnya => Repositori.nomorStrukBerikutnya();

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
        // Dua pil setinggi sama, bukan satu tombol teks di sebelah satu ikon
        // bulat. Keduanya mengurus benda yang sama — keranjang — jadi mereka
        // harus terbaca sebagai sepasang kontrol, bukan dua hal yang kebetulan
        // bertetangga.
        actions: [
          if (_jumlahItem > 0) ...[
            _TombolKosongkan(ringkas: ringkas, onTekan: _tanyaKosongkan),
            const SizedBox(width: Jarak.xs3),
          ],
          // Keranjang butuh jalan masuk yang selalu di tempat yang sama.
          // Sebelum ini satu-satunya cara membukanya adalah mengetuk bilah
          // mengambang — yang justru tidak ada saat keranjang masih kosong,
          // jadi tidak pernah ada tempat untuk belajar bahwa ia bisa dibuka.
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
                      if (produk.menipis || habis)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: _Pil(
                            teks: habis ? 'Habis' : 'Sisa ${produk.stok}',
                            bahaya: habis,
                          ),
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
class _TombolKosongkan extends StatelessWidget {
  const _TombolKosongkan({required this.ringkas, required this.onTekan});

  final bool ringkas;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;

    return Tooltip(
      message: 'Kosongkan keranjang',
      child: Semantics(
        button: true,
        label: 'Kosongkan keranjang',
        child: Material(
          color: a.bahayaLembut,
          borderRadius: BorderRadius.circular(Lengkung.bulat),
          child: InkWell(
            onTap: onTekan,
            borderRadius: BorderRadius.circular(Lengkung.bulat),
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(
                horizontal: ringkas ? Jarak.xs2 : Jarak.xs,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 19,
                    color: a.bahaya,
                  ),
                  if (!ringkas) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Kosongkan',
                      style: context.teks.labelLarge?.copyWith(
                        color: a.bahaya,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol keranjang di bilah atas.
///
/// Dua wujud dari satu tombol, bukan ikon berlencana: kosong ia garis samar
/// yang mati, terisi ia pil tinta pekat berisi angka. Lencana Material yang
/// menempel di pojok ikon mudah terlewat pada layar kecil — dan jumlah item
/// adalah satu-satunya alasan tombol ini dilirik saat tangan sedang penuh.
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
      child: Semantics(
        button: true,
        enabled: onTekan != null,
        child: Material(
          color: terisi ? a.fokus : Colors.transparent,
          borderRadius: BorderRadius.circular(Lengkung.bulat),
          child: InkWell(
            onTap: onTekan,
            borderRadius: BorderRadius.circular(Lengkung.bulat),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: Jarak.xs),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Lengkung.bulat),
                border: Border.all(
                  color: terisi ? a.fokus : context.warna.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: terisi
                        ? a.atasFokus
                        : context.warna.onSurfaceVariant,
                  ),
                  if (terisi) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$jumlah',
                      style: context.teks.labelLarge?.copyWith(
                        color: a.atasFokus,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
                child: Text('Keranjang', style: context.teks.titleLarge),
              ),
              // Bertinta bahaya, sama seperti kembarannya di bilah atas.
              // "Kosongkan" yang tampil netral di satu tempat dan merah di
              // tempat lain membuat orang mengira keduanya berbeda akibat.
              TextButton.icon(
                onPressed: onKosongkan,
                icon: const Icon(Icons.remove_shopping_cart_outlined, size: 18),
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
          TombolBundar(
            ikon: item.jumlah == 1 ? Icons.delete_outline : Icons.remove,
            bahaya: item.jumlah == 1,
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
                    child: OutlinedButton.icon(
                      onPressed: onKosongkan,
                      icon: const Icon(
                        Icons.remove_shopping_cart_outlined,
                        size: 18,
                      ),
                      label: const Text('Kosongkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.aksen.bahaya,
                        side: BorderSide(
                          color: context.aksen.bahaya.withValues(alpha: 0.35),
                        ),
                      ),
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
