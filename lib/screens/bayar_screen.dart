import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../util/pencetak_struk.dart';
import '../widgets/baris_pesanan.dart';
import '../widgets/isian_uang.dart';
import '../widgets/kartu.dart';
import '../widgets/lembar_diskon.dart';
import '../widgets/tombol_pil.dart';

class HasilKasir {
  const HasilKasir({required this.selesai, required this.item});

  final bool selesai;
  final List<ItemKeranjang> item;

  static const tersimpan = HasilKasir(selesai: true, item: []);
}

class BayarScreen extends StatefulWidget {
  const BayarScreen({
    super.key,
    required this.item,
    required this.nomorStruk,
    this.diskonTipe,
    this.diskonNilai = 0,
  });

  final List<ItemKeranjang> item;
  final String nomorStruk;
  final String? diskonTipe;
  final int diskonNilai;

  @override
  State<BayarScreen> createState() => _BayarScreenState();
}

class _BayarScreenState extends State<BayarScreen> {
  MetodeBayar _metode = MetodeBayar.tunai;
  final _uang = TextEditingController();
  bool _menyimpan = false;
  String? _galat;

  late final List<ItemKeranjang> _item = List.of(widget.item);

  String? _diskonTipe;
  int _diskonNilai = 0;

  @override
  void initState() {
    super.initState();
    _diskonTipe = widget.diskonTipe;
    _diskonNilai = widget.diskonNilai;
  }

  int get _subtotal => _item.fold(0, (n, i) => n + i.subtotal);

  int get _diskonNominal {
    if (_diskonNilai <= 0) return 0;
    if (_diskonTipe == 'PERSEN') {
      final p = _diskonNilai.clamp(0, 100);
      return (_subtotal * p / 100).round();
    }
    return _diskonNilai.clamp(0, _subtotal);
  }

  int get _total => (_subtotal - _diskonNominal).clamp(0, 999999999999);
  int get _jumlahItem => _item.fold(0, (n, i) => n + i.jumlah);

  int get _diterima => bacaNominal(_uang.text);
  bool get _tunai => _metode == MetodeBayar.tunai;
  int get _kembalian => _diterima - _total;
  bool get _bolehSimpan => !_tunai || _diterima >= _total;

  @override
  void dispose() {
    _uang.dispose();
    super.dispose();
  }

  void _ubah(String produkId, int delta) {
    final i = _item.indexWhere((e) => e.produk.id == produkId);
    if (i < 0) return;

    setState(() {
      final jumlah = _item[i].jumlah + delta;
      if (jumlah <= 0) {
        _item.removeAt(i);
      } else {
        _item[i] = ItemKeranjang(produk: _item[i].produk, jumlah: jumlah);
      }
    });

    if (_item.isEmpty) _tutup();
  }

  void _tutup() => Navigator.of(
    context,
  ).pop(HasilKasir(selesai: false, item: List.of(_item)));

  Future<void> _bukaDiskon() async {
    final hasil = await LembarDiskon.tampilkan(
      context,
      subtotal: _subtotal,
      diskonTipeAwal: _diskonTipe,
      diskonNilaiAwal: _diskonNilai,
    );
    if (hasil != null) {
      setState(() {
        _diskonTipe = hasil.$1;
        _diskonNilai = hasil.$2;
      });
    }
  }

  Future<void> _simpan() async {
    if (!_bolehSimpan) return;
    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      final transaksi = await Repositori.simpanTransaksi(
        item: _item,
        metode: _metode,
        status: StatusTransaksi.selesai,
        uangDiterima: _tunai ? _diterima : null,
        diskonTipe: _diskonTipe,
        diskonNilai: _diskonNilai,
      );
      await Repositori.catatTransaksiKeSesi(transaksi);
      if (!mounted) return;
      _keHasil(transaksi);
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = e.pesan;
      });
    }
  }

  Future<void> _bayarNanti() async {
    final pelanggan = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _LembarBayarNanti(total: _total),
    );
    if (pelanggan == null || !mounted) return;

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      final transaksi = await Repositori.simpanTransaksi(
        item: _item,
        metode: MetodeBayar.tunai,
        status: StatusTransaksi.ditahan,
        pelanggan: pelanggan,
        diskonTipe: _diskonTipe,
        diskonNilai: _diskonNilai,
      );
      if (!mounted) return;
      _keHasil(transaksi);
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = e.pesan;
      });
    }
  }

  /// Ganti layar ini dengan layar hasil, sambil **langsung** memberi tahu kasir
  /// bahwa transaksinya tersimpan.
  ///
  /// Kabarnya dikirim sekarang, bukan nanti saat layar hasil ditutup: begitu
  /// transaksi tercatat, keranjang lama sudah tidak berlaku. Menunda sampai
  /// pengguna menekan "Transaksi baru" berarti ada jendela waktu — sekecil apa
  /// pun — ketika penjualan sudah masuk tapi keranjangnya masih terisi.
  void _keHasil(Transaksi transaksi) {
    Navigator.of(context).pushReplacement<void, HasilKasir>(
      MaterialPageRoute<void>(
        builder: (_) => HasilBayarScreen(transaksi: transaksi),
      ),
      result: HasilKasir.tersimpan,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Ditahan supaya tombol kembali perangkat pun ikut membawa pesanan yang
      // barusan disunting; pop tanpa hasil akan membuat kasir memakai
      // keranjang versi lama.
      canPop: false,
      onPopInvokedWithResult: (sudah, _) {
        if (!sudah && !_menyimpan) _tutup();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          leading: IconButton(
            onPressed: _menyimpan ? null : _tutup,
            icon: const Icon(Icons.close),
            tooltip: 'Batal',
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                          label: 'Total tagihan',
                          nilai: rupiah(_total),
                          keterangan:
                              '$_jumlahItem item · ${widget.nomorStruk}',
                        ),
                        const SizedBox(height: Jarak.sm),

                        JudulBagian(
                          'Pesanan',
                          aksi: Text(
                            '$_jumlahItem item',
                            style: context.teks.bodySmall?.copyWith(
                              color: context.warna.onSurfaceVariant,
                            ),
                          ),
                        ),
                        KartuDaftar(
                          anak: [
                            for (final i in _item)
                              BarisPesanan(
                                nama: i.produk.nama,
                                gambarUrl: i.produk.gambarUrl,
                                hargaSatuan: i.produk.hargaJual,
                                jumlah: i.jumlah,
                                aktif: !_menyimpan,
                                bolehTambah:
                                    !i.produk.lacakStok ||
                                    i.jumlah < i.produk.stok,
                                onKurang: () => _ubah(i.produk.id, -1),
                                onTambah: () => _ubah(i.produk.id, 1),
                              ),
                          ],
                        ),
                        const SizedBox(height: Jarak.sm),

                        JudulBagian(
                          'Diskon',
                          aksi: _diskonNominal > 0
                              ? TextButton.icon(
                                  onPressed: _bukaDiskon,
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Ubah'),
                                )
                              : null,
                        ),
                        if (_diskonNominal > 0)
                          KartuDaftar(
                            anak: [
                              Padding(
                                padding: const EdgeInsets.all(Jarak.xs),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: context.aksen.bahayaLembut,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.discount_outlined,
                                        size: 20,
                                        color: context.aksen.bahaya,
                                      ),
                                    ),
                                    const SizedBox(width: Jarak.xs),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _diskonTipe == 'PERSEN'
                                                ? 'Diskon $_diskonNilai%'
                                                : 'Diskon Rp',
                                            style: context.teks.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Subtotal ${rupiah(_subtotal)}',
                                            style: context.teks.bodySmall?.copyWith(
                                              color: context.warna.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '-${rupiah(_diskonNominal)}',
                                      style: context.teks.titleMedium?.copyWith(
                                        color: context.aksen.bahaya,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _diskonTipe = null;
                                          _diskonNilai = 0;
                                        });
                                      },
                                      icon: const Icon(Icons.close, size: 18),
                                      tooltip: 'Hapus diskon',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _bukaDiskon,
                            icon: const Icon(Icons.discount_outlined, size: 18),
                            label: const Text('Tambah Diskon (Persen / Nominal)'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        const SizedBox(height: Jarak.sm),

                        const JudulBagian('Metode pembayaran'),
                        KartuDaftar(
                          anak: [
                            for (final m in MetodeBayar.values)
                              PilihanMetode(
                                metode: m,
                                terpilih: _metode == m,
                                onTekan: () => setState(() => _metode = m),
                              ),
                          ],
                        ),

                        if (_tunai) ...[
                          const SizedBox(height: Jarak.sm),
                          const JudulBagian('Uang diterima'),
                          IsianUang(
                            pengendali: _uang,
                            total: _total,
                            onUbah: () => setState(() {}),
                          ),
                          const SizedBox(height: Jarak.xs2),
                          BarisKembalian(
                            kembalian: _kembalian,
                            diisi: _diterima > 0,
                          ),
                        ] else ...[
                          const SizedBox(height: Jarak.sm),
                          CatatanNonTunai(metode: _metode, total: _total),
                        ],

                        if (_galat != null) ...[
                          const SizedBox(height: Jarak.sm),
                          BarisGalat(pesan: _galat!),
                        ],
                      ],
                    ),
                  ),
                  _KakiAksi(
                    bolehSimpan: _bolehSimpan,
                    menyimpan: _menyimpan,
                    onSimpan: _simpan,
                    onBayarNanti: _bayarNanti,
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

// ---------------------------------------------------------------------------
// Bagian-bagian layar bayar
// ---------------------------------------------------------------------------

class _KakiAksi extends StatelessWidget {
  const _KakiAksi({
    required this.bolehSimpan,
    required this.menyimpan,
    required this.onSimpan,
    required this.onBayarNanti,
  });

  final bool bolehSimpan;
  final bool menyimpan;
  final VoidCallback onSimpan;
  final VoidCallback onBayarNanti;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TombolPil(
            label: 'Simpan transaksi',
            memproses: menyimpan,
            onTekan: bolehSimpan && !menyimpan ? onSimpan : null,
          ),
          const SizedBox(height: Jarak.xs2),
          TextButton(
            onPressed: menyimpan ? null : onBayarNanti,
            style: TextButton.styleFrom(
              foregroundColor: context.warna.onSurfaceVariant,
            ),
            child: const Text('Bayar nanti'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bayar nanti
// ---------------------------------------------------------------------------

/// Lembar pencatat piutang.
///
/// Nama pembeli WAJIB. Piutang tanpa nama adalah piutang yang tidak akan
/// pernah ditagih — dan daftar utang yang isinya "Rp 45.000" tanpa keterangan
/// lebih buruk daripada tidak mencatat sama sekali, karena ia terlihat seperti
/// catatan yang benar.
class _LembarBayarNanti extends StatefulWidget {
  const _LembarBayarNanti({required this.total});

  final int total;

  @override
  State<_LembarBayarNanti> createState() => _LembarBayarNantiState();
}

class _LembarBayarNantiState extends State<_LembarBayarNanti> {
  final _nama = TextEditingController();
  bool _tersentuh = false;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kurang = _nama.text.trim().length < 2;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bayar nanti', style: context.teks.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Barang tetap keluar dan stok ikut berkurang, tapi '
                '${rupiah(widget.total)} belum dihitung sebagai omzet sampai '
                'dilunasi.',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: Jarak.sm),
              TextField(
                controller: _nama,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _kirim(kurang),
                decoration: InputDecoration(
                  labelText: 'Nama pembeli',
                  hintText: 'Mis. Bu Rina — meja 3',
                  errorText: _tersentuh && kurang
                      ? 'Nama pembeli wajib diisi.'
                      : null,
                ),
              ),
              const SizedBox(height: Jarak.sm),
              TombolPil(
                label: 'Catat sebagai piutang',
                onTekan: () => _kirim(kurang),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _kirim(bool kurang) {
    setState(() => _tersentuh = true);
    if (kurang) return;
    Navigator.of(context).pop(_nama.text.trim());
  }
}

// ---------------------------------------------------------------------------
// Hasil
// ---------------------------------------------------------------------------

/// Layar setelah transaksi tersimpan.
///
/// Kembaliannya ditampilkan BESAR dan sendirian. Itu satu-satunya angka yang
/// dibutuhkan kasir pada detik ini, dan menaruhnya sejajar dengan angka lain
/// berarti memaksa orang mencarinya sambil memegang uang pembeli.
class HasilBayarScreen extends StatelessWidget {
  const HasilBayarScreen({super.key, required this.transaksi});

  final Transaksi transaksi;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final piutang = transaksi.piutang;
    final kembalian = transaksi.kembalian;

    return PopScope(
      // Tombol kembali perangkat harus keluar dari alur bayar, bukan mundur ke
      // layar nominal yang transaksinya sudah tersimpan.
      canPop: false,
      onPopInvokedWithResult: (sudah, _) {
        if (!sudah) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Jarak.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: Jarak.md),
                          Icon(
                            piutang
                                ? Icons.schedule_outlined
                                : Icons.check_circle_outline,
                            size: 56,
                            color: piutang ? a.peringatan : a.sukses,
                          ),
                          const SizedBox(height: Jarak.sm),
                          Text(
                            piutang
                                ? 'Dicatat sebagai piutang'
                                : 'Transaksi tersimpan',
                            textAlign: TextAlign.center,
                            style: context.teks.headlineSmall,
                          ),
                          const SizedBox(height: Jarak.xs3),
                          Text(
                            piutang
                                ? '${transaksi.pelanggan} belum membayar '
                                      '${rupiah(transaksi.total)}. Tagih lewat '
                                      'daftar Bayar nanti.'
                                : '${transaksi.jumlahItem} item · '
                                      '${transaksi.metode.label}',
                            textAlign: TextAlign.center,
                            style: context.teks.bodyMedium?.copyWith(
                              color: context.warna.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),

                          if (kembalian != null && !piutang) ...[
                            const SizedBox(height: Jarak.lg),
                            PanelKembalian(nilai: kembalian),
                          ],

                          const SizedBox(height: Jarak.lg),
                          KartuDaftar(
                            anak: [
                              BarisDaftar(
                                awalan: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 22,
                                  color: context.warna.onSurfaceVariant,
                                ),
                                judul: transaksi.nomorStruk,
                                keterangan: jam(transaksi.waktu),
                                akhiran: rupiah(
                                  transaksi.adaDiskon
                                      ? transaksi.subtotal
                                      : transaksi.total,
                                ),
                              ),
                              if (transaksi.adaDiskon) ...[
                                BarisDaftar(
                                  awalan: Icon(
                                    Icons.discount_outlined,
                                    size: 20,
                                    color: context.aksen.bahaya,
                                  ),
                                  judul: transaksi.diskonTipe == 'PERSEN'
                                      ? 'Diskon ${transaksi.diskonNilai}%'
                                      : 'Diskon Rp',
                                  keterangan: 'Potongan harga',
                                  akhiran: '-${rupiah(transaksi.diskonNominal)}',
                                ),
                                BarisDaftar(
                                  awalan: Icon(
                                    Icons.payments_outlined,
                                    size: 20,
                                    color: context.aksen.fokus,
                                  ),
                                  judul: 'Total Bayar',
                                  keterangan: '${transaksi.jumlahItem} item',
                                  akhiran: rupiah(transaksi.total),
                                ),
                              ],
                            ],
                          ),
                        ],
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
                    // Keduanya selebar penuh dan setinggi sama: dua tombol yang
                    // bertumpuk dengan lebar berbeda terbaca seperti satu
                    // tombol utama dan satu sisa, padahal mencetak struk sama
                    // sahnya dengan memulai transaksi berikutnya.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TombolPil(
                          label: 'Transaksi baru',
                          onTekan: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: Jarak.xs2),
                        Row(
                          children: [
                            Expanded(
                              child: TombolPilGaris(
                                ikon: Icons.print_outlined,
                                label: 'Cetak struk',
                                onTekan: () => _cetakStruk(context),
                              ),
                            ),
                            const SizedBox(width: Jarak.xs2),
                            Expanded(
                              child: TombolPilGaris(
                                ikon: Icons.share_outlined,
                                label: 'Bagikan',
                                onTekan: () => _bagikanStruk(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cetakStruk(BuildContext context) async {
    try {
      final toko = await Repositori.toko();
      final pengaturan = await Repositori.pengaturanStruk();
      if (!context.mounted) return;
      await PencetakStruk.cetakOtomatisBluetooth(
        context,
        toko: toko,
        pengaturan: pengaturan,
        transaksi: transaksi,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak struk: $e')),
      );
    }
  }

  Future<void> _bagikanStruk(BuildContext context) async {
    try {
      final toko = await Repositori.toko();
      final pengaturan = await Repositori.pengaturanStruk();
      if (!context.mounted) return;
      await PencetakStruk.bagikanStruk(
        context,
        toko: toko,
        pengaturan: pengaturan,
        transaksi: transaksi,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membagikan struk: $e')),
      );
    }
  }
}
