import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/isian_uang.dart';
import '../widgets/kartu.dart';
import '../widgets/tombol_pil.dart';

/// Layar pembayaran satu transaksi.
///
/// Sebelumnya ini cuma lembar bawah berisi tiga pilihan metode: ditekan, dan
/// transaksinya langsung dianggap selesai. Yang hilang justru bagian yang
/// paling sering salah di kasir sungguhan — menghitung kembalian. Kasir yang
/// harus menghitung di kepala sambil pembeli menunggu adalah kasir yang
/// cepat atau lambat memberi kembalian keliru.
///
/// Karena itu ia jadi halaman, bukan lembar: uang diterima, kembalian, dan
/// tombol simpan butuh ruang yang tidak berebut dengan papan ketik.
class BayarScreen extends StatefulWidget {
  const BayarScreen({super.key, required this.item, required this.nomorStruk});

  final List<ItemKeranjang> item;
  final String nomorStruk;

  @override
  State<BayarScreen> createState() => _BayarScreenState();
}

class _BayarScreenState extends State<BayarScreen> {
  MetodeBayar _metode = MetodeBayar.tunai;
  final _uang = TextEditingController();
  bool _menyimpan = false;
  String? _galat;

  int get _total => widget.item.fold(0, (n, i) => n + i.subtotal);
  int get _jumlahItem => widget.item.fold(0, (n, i) => n + i.jumlah);

  /// Nilai yang sedang diketik, tanpa titik pemisah.
  int get _diterima => bacaNominal(_uang.text);

  bool get _tunai => _metode == MetodeBayar.tunai;
  int get _kembalian => _diterima - _total;

  /// Tunai baru boleh disimpan kalau uangnya cukup. Metode lain tidak menuntut
  /// nominal — yang dikonfirmasi kasir di situ adalah dananya sudah masuk.
  bool get _bolehSimpan => !_tunai || _diterima >= _total;

  @override
  void dispose() {
    _uang.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_bolehSimpan) return;
    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      final transaksi = await Repositori.simpanTransaksi(
        item: widget.item,
        metode: _metode,
        status: StatusTransaksi.selesai,
        uangDiterima: _tunai ? _diterima : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HasilBayarScreen(transaksi: transaksi),
        ),
      );
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
        item: widget.item,
        // Metode dicatat apa adanya sebagai tunai: piutang ini nantinya hampir
        // selalu dilunasi tunai, dan kalau ternyata bukan, pelunasannya yang
        // mengoreksi. Menambah metode "utang" akan mencemari laporan metode
        // pembayaran dengan sesuatu yang bukan cara membayar.
        metode: MetodeBayar.tunai,
        status: StatusTransaksi.ditahan,
        pelanggan: pelanggan,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HasilBayarScreen(transaksi: transaksi),
        ),
      );
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = e.pesan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        leading: IconButton(
          onPressed: _menyimpan ? null : () => Navigator.of(context).maybePop(),
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
                            _PanelKembalian(nilai: kembalian),
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
                                akhiran: rupiah(transaksi.total),
                              ),
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
                    child: Column(
                      children: [
                        TombolPil(
                          label: 'Transaksi baru',
                          onTekan: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: Jarak.xs2),
                        OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Printer belum tersambung. '
                                  'Atur di Akun · Struk & printer.',
                                ),
                              ),
                            ),
                          icon: const Icon(Icons.print_outlined, size: 20),
                          label: const Text('Cetak struk'),
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
}

class _PanelKembalian extends StatelessWidget {
  const _PanelKembalian({required this.nilai});

  final int nilai;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Jarak.sm,
        vertical: Jarak.md,
      ),
      decoration: BoxDecoration(
        color: nilai > 0 ? a.suksesLembut : a.isian,
        borderRadius: BorderRadius.circular(Lengkung.panel),
      ),
      child: Column(
        children: [
          Text(
            nilai > 0 ? 'KEMBALIAN' : 'UANG PAS',
            style: context.teks.labelSmall?.copyWith(
              color: nilai > 0 ? a.sukses : context.warna.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          if (nilai > 0) ...[
            const SizedBox(height: Jarak.xs3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rupiah(nilai),
                style: context.teks.displaySmall?.copyWith(
                  color: a.sukses,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
