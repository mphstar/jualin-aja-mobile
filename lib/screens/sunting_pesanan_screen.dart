import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/baris_pesanan.dart';
import '../widgets/bingkai.dart';
import '../widgets/blok_foto.dart';
import '../widgets/isian_uang.dart' show BarisGalat;
import '../widgets/kartu.dart';
import '../widgets/rangka.dart';
import '../widgets/tombol_pil.dart';

/// Ubah isi pesanan sebuah piutang.
///
/// Ada karena utang warung jarang berhenti di satu kunjungan. Orang yang
/// kemarin mengambil dua kopi hari ini menambah satu roti, dan dicatat sebagai
/// piutang kedua atas nama yang sama — dua baris di daftar tagihan untuk satu
/// orang yang datang membayar sekali. Layar ini membuat pesanannya bisa
/// disusul, bukan digandakan.
///
/// **Hanya untuk yang belum lunas.** Struk yang sudah dibayar tidak dibawa ke
/// sini sama sekali; aturannya ditegakkan lagi di [Repositori.ubahIsiTransaksi]
/// supaya tidak bergantung pada layar yang menahannya.
class SuntingPesananScreen extends StatelessWidget {
  const SuntingPesananScreen({super.key, required this.transaksi});

  final Transaksi transaksi;

  /// Buka layarnya. Mengembalikan true kalau perubahannya benar-benar
  /// tersimpan.
  static Future<bool> tampilkan(
    BuildContext context,
    Transaksi transaksi,
  ) async {
    final tersimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SuntingPesananScreen(transaksi: transaksi),
      ),
    );
    return tersimpan ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah pesanan')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            // Katalog dimuat di sini, bukan di dalam formulir: menambah barang
            // butuh daftar produk beserta stoknya, dan formulir yang mengambil
            // datanya sendiri akan punya keadaan memuat kedua di tengah layar
            // yang isinya sudah tampil.
            child: Bingkai<List<Produk>>(
              ambil: Repositori.produk,
              rangka: const Padding(
                padding: EdgeInsets.all(Jarak.sm),
                child: Column(
                  children: [
                    RangkaPanel(tinggi: 104),
                    SizedBox(height: Jarak.md),
                    RangkaDaftar(baris: 4),
                  ],
                ),
              ),
              isi: (context, produk) =>
                  _Formulir(transaksi: transaksi, katalog: produk),
            ),
          ),
        ),
      ),
    );
  }
}

class _Formulir extends StatefulWidget {
  const _Formulir({required this.transaksi, required this.katalog});

  final Transaksi transaksi;
  final List<Produk> katalog;

  @override
  State<_Formulir> createState() => _FormulirState();
}

class _FormulirState extends State<_Formulir> {
  late final List<BarisStruk> _baris = List.of(widget.transaksi.baris);
  final _kendaliCari = TextEditingController();
  String _cari = '';

  bool _menyimpan = false;
  String? _galat;

  @override
  void dispose() {
    _kendaliCari.dispose();
    super.dispose();
  }

  int get _total => _baris.fold(0, (n, b) => n + b.subtotal);
  int get _jumlahItem => _baris.fold(0, (n, b) => n + b.jumlah);
  int get _totalSemula => widget.transaksi.total;
  int get _selisih => _total - _totalSemula;

  /// Dibandingkan per baris, bukan lewat totalnya.
  ///
  /// Membuang satu barang lalu menambah barang lain seharga sama menghasilkan
  /// total yang persis sama — dan tombol simpan yang tetap mati di situ adalah
  /// tombol yang menolak menyimpan perubahan yang jelas-jelas terjadi.
  bool get _berubah {
    final lama = {for (final b in widget.transaksi.baris) b.produkId: b.jumlah};
    final baru = {for (final b in _baris) b.produkId: b.jumlah};
    if (lama.length != baru.length) return true;
    for (final e in baru.entries) {
      if (lama[e.key] != e.value) return true;
    }
    return false;
  }

  int _jumlahAwal(String produkId) => widget.transaksi.baris
      .where((b) => b.produkId == produkId)
      .fold(0, (n, b) => n + b.jumlah);

  int _jumlahKini(String produkId) => _baris
      .where((b) => b.produkId == produkId)
      .fold(0, (n, b) => n + b.jumlah);

  Produk? _produk(String id) {
    for (final p in widget.katalog) {
      if (p.id == id) return p;
    }
    // Produk yang sudah dihapus dari master data. Barisnya tetap ditampilkan —
    // ia bagian dari utang yang nyata — hanya tidak bisa ditambah lagi.
    return null;
  }

  /// Sisa yang masih boleh ditambahkan ke struk ini.
  ///
  /// Stok di master data sudah dikurangi saat piutangnya dibuat, jadi jatah
  /// baris ini adalah sisa rak **ditambah** yang sudah tercatat di struk ini
  /// sendiri. Tanpa penambahan itu, item yang menghabiskan stok tidak akan
  /// bisa dikembalikan setelah dikurangi sekali.
  int _sisa(Produk p) {
    if (!p.lacakStok) return 1 << 31;
    return p.stok + _jumlahAwal(p.id) - _jumlahKini(p.id);
  }

  void _ubah(String produkId, int delta) {
    setState(() {
      final i = _baris.indexWhere((b) => b.produkId == produkId);
      if (i < 0) return;
      final jumlah = _baris[i].jumlah + delta;
      if (jumlah <= 0) {
        _baris.removeAt(i);
      } else {
        final b = _baris[i];
        _baris[i] = BarisStruk(
          produkId: b.produkId,
          nama: b.nama,
          // Harga baris lama TIDAK ikut disegarkan. Pembeli mengambil barangnya
          // pada harga hari itu; menaikkannya sekarang berarti menagih selisih
          // yang tidak pernah disepakati.
          hargaSatuan: b.hargaSatuan,
          jumlah: jumlah,
        );
      }
    });
  }

  /// Tambah satu produk. Yang sudah ada di struk cuma naik jumlahnya — dua
  /// baris untuk barang yang sama membuat struknya terbaca seperti dua kali
  /// pembelian.
  void _tambah(Produk p) {
    setState(() {
      final i = _baris.indexWhere((b) => b.produkId == p.id);
      if (i >= 0) {
        _baris[i] = BarisStruk(
          produkId: p.id,
          nama: _baris[i].nama,
          hargaSatuan: _baris[i].hargaSatuan,
          jumlah: _baris[i].jumlah + 1,
        );
      } else {
        _baris.add(
          BarisStruk(
            produkId: p.id,
            nama: p.nama,
            // Baris baru dicatat pada harga hari ini — ia memang barang yang
            // baru diambil sekarang.
            hargaSatuan: p.hargaJual,
            jumlah: 1,
          ),
        );
      }
    });
  }

  Future<void> _simpan() async {
    if (!_berubah || _baris.isEmpty) return;

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      await Repositori.ubahIsiTransaksi(
        widget.transaksi,
        baris: List.of(_baris),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = e.pesan;
      });
    }
  }

  /// Menutup layar dengan perubahan yang belum disimpan selalu bertanya dulu.
  ///
  /// Menambah lima barang lalu tidak sengaja menekan kembali berarti mengetik
  /// ulang seluruhnya — dan tidak ada satu pun jejak yang memberitahu bahwa
  /// pekerjaannya hilang.
  Future<bool> _bolehKeluar() async {
    if (!_berubah || _menyimpan) return true;

    final buang = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text(
          'Pesanan yang barusan diubah belum disimpan. Piutangnya akan kembali '
          'seperti semula.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Lanjut menyunting'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.aksen.bahaya,
              foregroundColor: context.warna.onError,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return buang ?? false;
  }

  List<Produk> get _terlihat {
    final kunci = _cari.trim().toLowerCase();
    if (kunci.isEmpty) return widget.katalog;
    return widget.katalog
        .where((p) => p.nama.toLowerCase().contains(kunci))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaksi;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (sudah, _) async {
        if (sudah) return;
        if (await _bolehKeluar() && mounted) {
          if (!context.mounted) return;
          Navigator.of(context).pop(false);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Jarak.sm,
                Jarak.xs,
                Jarak.sm,
                Jarak.sm,
              ),
              children: [
                PanelAngka(
                  label: 'Total pesanan',
                  nilai: rupiah(_total),
                  keterangan:
                      '${t.pelanggan ?? 'Pembeli'} · ${t.nomorStruk} · '
                      '$_jumlahItem item',
                ),
                if (_selisih != 0) ...[
                  const SizedBox(height: Jarak.xs2),
                  _BarisSelisih(semula: _totalSemula, selisih: _selisih),
                ],
                const SizedBox(height: Jarak.md),

                JudulBagian(
                  'Isi pesanan',
                  aksi: Text(
                    '$_jumlahItem item',
                    style: context.teks.bodySmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_baris.isEmpty)
                  const _PesananKosong()
                else
                  KartuDaftar(
                    anak: [
                      for (final b in _baris)
                        BarisPesanan(
                          nama: b.nama,
                          gambarUrl: _produk(b.produkId)?.gambarUrl,
                          hargaSatuan: b.hargaSatuan,
                          jumlah: b.jumlah,
                          aktif: !_menyimpan,
                          bolehTambah: switch (_produk(b.produkId)) {
                            final p? => _sisa(p) > 0,
                            // Produk yang sudah dihapus dari master data tidak
                            // punya stok untuk dipotong lagi.
                            null => false,
                          },
                          onKurang: () => _ubah(b.produkId, -1),
                          onTambah: () => _ubah(b.produkId, 1),
                        ),
                    ],
                  ),

                const SizedBox(height: Jarak.md),
                const JudulBagian('Tambah barang'),
                TextField(
                  controller: _kendaliCari,
                  enabled: !_menyimpan,
                  onChanged: (v) => setState(() => _cari = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari produk',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _cari.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _kendaliCari.clear();
                              setState(() => _cari = '');
                            },
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Hapus pencarian',
                          ),
                  ),
                ),
                const SizedBox(height: Jarak.xs2),
                if (_terlihat.isEmpty)
                  _Kosong(
                    pesan: _cari.trim().isEmpty
                        ? 'Belum ada produk di master data.'
                        : 'Tidak ada produk bernama "${_cari.trim()}".',
                  )
                else
                  KartuDaftar(
                    anak: [
                      for (final p in _terlihat)
                        _BarisKatalog(
                          produk: p,
                          diPesanan: _jumlahKini(p.id),
                          sisa: _sisa(p),
                          aktif: !_menyimpan,
                          onTambah: () => _tambah(p),
                        ),
                    ],
                  ),

                if (_galat != null) ...[
                  const SizedBox(height: Jarak.sm),
                  BarisGalat(pesan: _galat!),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              Jarak.sm,
              Jarak.xs,
              Jarak.sm,
              Jarak.sm,
            ),
            decoration: BoxDecoration(
              color: context.warna.surface,
              border: Border(top: BorderSide(color: context.warna.outline)),
            ),
            child: TombolPil(
              label: 'Simpan perubahan',
              memproses: _menyimpan,
              onTekan: _berubah && _baris.isNotEmpty && !_menyimpan
                  ? _simpan
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selisih terhadap nominal yang tercatat sebelumnya.
///
/// Angka utang yang berubah tanpa keterangan adalah angka yang akan
/// diperdebatkan di depan pembeli. Baris ini menyebutkan berapa semula dan
/// berapa bedanya, sebelum tombol simpan ditekan.
class _BarisSelisih extends StatelessWidget {
  const _BarisSelisih({required this.semula, required this.selisih});

  final int semula;
  final int selisih;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final naik = selisih > 0;
    final warna = naik ? a.peringatan : a.sukses;

    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: naik ? a.peringatanLembut : a.suksesLembut,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
      ),
      child: Row(
        children: [
          Icon(
            naik ? Icons.trending_up : Icons.trending_down,
            size: 20,
            color: warna,
          ),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              'Semula ${rupiah(semula)} · '
              '${naik ? 'bertambah' : 'berkurang'} ${rupiah(selisih.abs())}',
              style: context.teks.bodySmall?.copyWith(
                color: warna,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu produk di katalog tambah.
///
/// Seluruh barisnya tombol tambah, sama seperti kartu produk di kasir — bukan
/// hanya ikon "+" di ujung kanan.
class _BarisKatalog extends StatelessWidget {
  const _BarisKatalog({
    required this.produk,
    required this.diPesanan,
    required this.sisa,
    required this.aktif,
    required this.onTambah,
  });

  final Produk produk;
  final int diPesanan;

  /// Sisa yang masih boleh ditambahkan ke struk ini — sudah memperhitungkan
  /// yang sudah tercatat di dalamnya.
  final int sisa;

  final bool aktif;
  final VoidCallback onTambah;

  @override
  Widget build(BuildContext context) {
    final boleh = aktif && sisa > 0;

    final keterangan = StringBuffer(rupiah(produk.hargaJual));
    if (diPesanan > 0) keterangan.write(' · $diPesanan di pesanan');
    if (produk.lacakStok) {
      keterangan.write(sisa > 0 ? ' · sisa $sisa' : ' · stok habis');
    }

    return Opacity(
      opacity: sisa > 0 ? 1 : 0.5,
      child: BarisDaftar(
        awalan: SizedBox(
          width: 40,
          height: 40,
          child: BlokFoto(url: produk.gambarUrl, tampilkanLabel: false),
        ),
        judul: produk.nama,
        keterangan: keterangan.toString(),
        warnaKeterangan: produk.lacakStok && sisa <= 0
            ? context.aksen.bahaya
            : null,
        bawahAkhiran: TombolBundar(
          ikon: Icons.add,
          utama: true,
          onTekan: boleh ? onTambah : null,
        ),
        onTekan: boleh ? onTambah : null,
      ),
    );
  }
}

/// Pesanan yang dikosongkan seluruhnya.
///
/// Tidak dilarang sambil menyunting — kasir boleh membuang semuanya lalu
/// menyusun ulang. Yang dilarang cuma menyimpannya: piutang tanpa isi adalah
/// tagihan tanpa alasan, dan membatalkan utang bukan pekerjaan layar ini.
class _PesananKosong extends StatelessWidget {
  const _PesananKosong();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.aksen.bahayaLembut,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: context.aksen.bahaya),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              'Pesanan kosong. Tambahkan setidaknya satu barang sebelum '
              'menyimpan — piutang tanpa isi tidak bisa ditagih.',
              style: context.teks.bodySmall?.copyWith(
                color: context.aksen.bahaya,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.sm),
      decoration: BoxDecoration(
        color: context.aksen.kartuAlt,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      alignment: Alignment.center,
      child: Text(
        pesan,
        textAlign: TextAlign.center,
        style: context.teks.bodySmall?.copyWith(
          color: context.warna.onSurfaceVariant,
        ),
      ),
    );
  }
}
