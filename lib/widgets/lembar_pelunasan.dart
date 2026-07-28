import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'isian_uang.dart';
import 'kartu.dart';
import 'tombol_pil.dart';

/// Terima pembayaran sebuah piutang.
///
/// Bentuknya sengaja sama persis dengan layar bayar di kasir — metode, uang
/// diterima, kembalian. Bagi kasir ini memang transaksi yang sama, cuma
/// terlambat; menyederhanakannya jadi satu tombol "Tandai lunas" berarti
/// menyuruh dia menghitung kembalian di kepala justru pada transaksi yang
/// nominalnya sudah tidak diingat siapa pun.
///
/// Mengembalikan `true` kalau piutangnya benar-benar tersimpan lunas.
Future<bool> tampilkanLembarPelunasan(
  BuildContext context,
  Transaksi transaksi,
) async {
  final lunas = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _LembarPelunasan(transaksi: transaksi),
  );
  return lunas ?? false;
}

/// Keterangan bahwa printer belum tersambung — sama bunyinya dengan yang
/// muncul di layar hasil kasir dan di cetak ulang struk.
class _CatatanPrinter extends StatelessWidget {
  const _CatatanPrinter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.aksen.kartuAlt,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.print_disabled_outlined,
            size: 20,
            color: context.warna.onSurfaceVariant,
          ),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              'Printer belum tersambung. Atur di Akun · Struk & printer, lalu '
              'cetak ulang dari struknya di Riwayat.',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LembarPelunasan extends StatefulWidget {
  const _LembarPelunasan({required this.transaksi});

  final Transaksi transaksi;

  @override
  State<_LembarPelunasan> createState() => _LembarPelunasanState();
}

class _LembarPelunasanState extends State<_LembarPelunasan> {
  MetodeBayar _metode = MetodeBayar.tunai;
  final _uang = TextEditingController();
  bool _menyimpan = false;
  String? _galat;

  /// Terisi begitu pelunasannya tersimpan. Selama masih null, lembar ini
  /// formulir; sesudahnya ia halaman hasil.
  ///
  /// Lembarnya tidak langsung ditutup setelah tersimpan karena masih ada satu
  /// keputusan yang tersisa — dicetak atau tidak — dan kembalian yang harus
  /// terbaca sekali lihat. Menutupnya sendiri berarti memutuskan keduanya
  /// untuk kasir.
  Transaksi? _lunas;

  /// True setelah "Cetak struk" ditekan di halaman hasil.
  bool _mintaCetak = false;

  int get _total => widget.transaksi.total;
  int get _diterima => bacaNominal(_uang.text);

  bool get _tunai => _metode == MetodeBayar.tunai;
  int get _kembalian => _diterima - _total;

  /// Sama seperti di kasir: tunai baru boleh disimpan kalau uangnya cukup.
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
      final lunas = await Repositori.lunasiTransaksi(
        widget.transaksi,
        metode: _metode,
        uangDiterima: _tunai ? _diterima : null,
      );
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _lunas = lunas;
      });
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
    final t = widget.transaksi;

    return PopScope(
      // Setelah tersimpan, lembar ini tidak boleh tertutup "tanpa hasil".
      // Menariknya ke bawah atau menyentuh latar adalah cara yang wajar untuk
      // menyelesaikannya — dan pelunasan yang sudah tercatat tapi dilaporkan
      // sebagai batal membuat layar di belakangnya diam saja seolah tidak
      // terjadi apa-apa.
      canPop: _lunas == null && !_menyimpan,
      onPopInvokedWithResult: (sudah, _) {
        if (sudah || _menyimpan) return;
        Navigator.of(context).pop(true);
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
            child: _lunas == null ? _formulir(context, t) : _hasil(context),
          ),
        ),
      ),
    );
  }

  Widget _formulir(BuildContext context, Transaksi t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Terima pembayaran', style: context.teks.titleLarge),
        const SizedBox(height: 2),
        Text(
          '${t.pelanggan ?? 'Pembeli'} · ${t.nomorStruk} · '
          'utang sejak ${relatif(t.waktu)}',
          style: context.teks.bodySmall?.copyWith(
            color: context.warna.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: Jarak.sm),

        PanelAngka(
          label: 'Sisa utang',
          nilai: rupiah(_total),
          keterangan: '${t.jumlahItem} item',
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
            // Kalimat "utang sejak …" di atas harus sempat terbaca dulu.
            fokusOtomatis: false,
          ),
          const SizedBox(height: Jarak.xs2),
          BarisKembalian(kembalian: _kembalian, diisi: _diterima > 0),
        ] else ...[
          const SizedBox(height: Jarak.sm),
          CatatanNonTunai(metode: _metode, total: _total),
        ],

        if (_galat != null) ...[
          const SizedBox(height: Jarak.sm),
          BarisGalat(pesan: _galat!),
        ],

        const SizedBox(height: Jarak.sm),
        TombolPil(
          label: 'Catat lunas',
          memproses: _menyimpan,
          onTekan: _bolehSimpan && !_menyimpan ? _simpan : null,
        ),
        const SizedBox(height: Jarak.xs3),
        Text(
          'Omzet tetap tercatat di ${tanggal(t.waktu)} — hari barangnya '
          'keluar, bukan hari uangnya masuk.',
          textAlign: TextAlign.center,
          style: context.teks.bodySmall?.copyWith(
            color: context.warna.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Halaman hasil, di dalam lembar yang sama.
  ///
  /// Susunannya sengaja kembar dengan layar hasil di kasir: kembalian besar dan
  /// sendirian, lalu dua tombol selebar penuh. Pelunasan piutang bagi kasir
  /// adalah transaksi yang sama, cuma terlambat — dan yang terasa sama harus
  /// terlihat sama.
  Widget _hasil(BuildContext context) {
    final a = context.aksen;
    final t = _lunas!;
    final kembalian = t.kembalian;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: a.sukses),
        const SizedBox(height: Jarak.xs2),
        Text(
          'Piutang lunas',
          textAlign: TextAlign.center,
          style: context.teks.headlineSmall,
        ),
        const SizedBox(height: Jarak.xs3),
        Text(
          '${t.pelanggan ?? 'Pembeli'} · ${t.nomorStruk} · '
          '${rupiah(t.total)} · ${t.metode.label}',
          textAlign: TextAlign.center,
          style: context.teks.bodySmall?.copyWith(
            color: context.warna.onSurfaceVariant,
            height: 1.45,
          ),
        ),

        if (kembalian != null) ...[
          const SizedBox(height: Jarak.md),
          PanelKembalian(nilai: kembalian),
        ],

        const SizedBox(height: Jarak.md),
        TombolPil(
          label: 'Selesai',
          onTekan: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: Jarak.xs2),
        // Mencetak tetap jadi pilihan, bukan akibat otomatis dari melunasi.
        // Sebagian pembeli warung tidak mau struk sama sekali, dan kertas yang
        // keluar sendiri untuk setiap pelunasan hanya menghabiskan gulungan.
        TombolPilGaris(
          ikon: Icons.print_outlined,
          label: 'Cetak struk',
          onTekan: () => setState(() => _mintaCetak = true),
        ),
        if (_mintaCetak) ...[
          const SizedBox(height: Jarak.xs2),
          // Pesannya inline, bukan snackbar: lembar ini menutupi bagian bawah
          // layar, dan toast yang muncul di baliknya adalah toast yang tidak
          // pernah terbaca.
          const _CatatanPrinter(),
        ],
      ],
    );
  }
}
