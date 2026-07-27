import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/bingkai.dart';
import '../widgets/kartu.dart';
import '../widgets/rangka.dart';
import '../widgets/tombol_pil.dart';

/// Pengaturan struk & printer.
///
/// Seluruh layar ini berputar di sekitar satu benda: pratinjau struknya, yang
/// berubah seketika setiap sakelar disentuh. Pengaturan cetak tanpa pratinjau
/// adalah tebak-tebakan yang baru ketahuan hasilnya setelah kertas terlanjur
/// keluar — dan kertas struk tidak bisa di-undo.
class StrukScreen extends StatelessWidget {
  const StrukScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Struk & printer')),
      body: SafeArea(
        top: false,
        child: Bingkai<(Toko, PengaturanStruk)>(
          ambil: () async {
            final toko = await Repositori.toko();
            final struk = await Repositori.pengaturanStruk();
            return (toko, struk);
          },
          rangka: const Padding(
            padding: EdgeInsets.all(Jarak.sm),
            child: Column(
              children: [
                RangkaPanel(tinggi: 220),
                SizedBox(height: Jarak.md),
              ],
            ),
          ),
          isi: (context, data) => _Isi(toko: data.$1, awal: data.$2),
        ),
      ),
    );
  }
}

class _Isi extends StatefulWidget {
  const _Isi({required this.toko, required this.awal});

  final Toko toko;
  final PengaturanStruk awal;

  @override
  State<_Isi> createState() => _IsiState();
}

class _IsiState extends State<_Isi> {
  late final TextEditingController _kepala;
  late final TextEditingController _kaki;
  late PengaturanStruk _nilai;

  bool _menyimpan = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _nilai = widget.awal;
    _kepala = TextEditingController(text: _nilai.kepala);
    _kaki = TextEditingController(text: _nilai.kaki);
  }

  @override
  void dispose() {
    _kepala.dispose();
    _kaki.dispose();
    super.dispose();
  }

  void _ubah(PengaturanStruk baru) => setState(() => _nilai = baru);

  Future<void> _simpan() async {
    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      await Repositori.simpanPengaturanStruk(
        _nilai.salin(kepala: _kepala.text.trim(), kaki: _kaki.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Pengaturan struk disimpan')),
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
    // Pratinjau memakai isian yang SEDANG diketik, bukan yang sudah disimpan —
    // kalau ia baru ikut setelah tombol Simpan ditekan, ia bukan pratinjau.
    final pratinjau = _nilai.salin(
      kepala: _kepala.text.trim(),
      kaki: _kaki.text.trim(),
    );

    return Center(
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
                  const JudulBagian('Pratinjau'),
                  PratinjauStruk(toko: widget.toko, pengaturan: pratinjau),

                  const SizedBox(height: Jarak.md),
                  const JudulBagian('Lebar kertas'),
                  KartuDaftar(
                    anak: [
                      for (final l in LebarKertas.values)
                        BarisDaftar(
                          awalan: Icon(
                            Icons.receipt_outlined,
                            size: 22,
                            color: context.warna.onSurface,
                          ),
                          judul: l.label,
                          keterangan: l.keterangan,
                          bawahAkhiran: Icon(
                            _nilai.lebar == l
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 22,
                            color: _nilai.lebar == l
                                ? context.warna.onSurface
                                : context.warna.onSurfaceVariant,
                          ),
                          onTekan: () => _ubah(_nilai.salin(lebar: l)),
                        ),
                    ],
                  ),

                  const SizedBox(height: Jarak.md),
                  const JudulBagian('Teks tambahan'),
                  TextField(
                    controller: _kepala,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 60,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Kepala struk',
                      hintText: 'Mis. Terima kasih sudah mampir',
                    ),
                  ),
                  TextField(
                    controller: _kaki,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 80,
                    maxLines: 2,
                    minLines: 1,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Kaki struk',
                      hintText:
                          'Mis. Barang yang sudah dibeli tidak dapat ditukar',
                    ),
                  ),

                  const SizedBox(height: Jarak.xs2),
                  const JudulBagian('Yang ikut dicetak'),
                  KartuDaftar(
                    anak: [
                      _Sakelar(
                        judul: 'Alamat toko',
                        keterangan: widget.toko.alamat,
                        nilai: _nilai.tampilkanAlamat,
                        onUbah: (v) => _ubah(_nilai.salin(tampilkanAlamat: v)),
                      ),
                      _Sakelar(
                        judul: 'Nomor telepon',
                        keterangan: widget.toko.telepon,
                        nilai: _nilai.tampilkanTelepon,
                        onUbah: (v) => _ubah(_nilai.salin(tampilkanTelepon: v)),
                      ),
                      _Sakelar(
                        judul: 'Nama kasir',
                        keterangan: 'Berguna kalau tokonya bergantian penjaga',
                        nilai: _nilai.tampilkanNamaKasir,
                        onUbah: (v) =>
                            _ubah(_nilai.salin(tampilkanNamaKasir: v)),
                      ),
                    ],
                  ),

                  const SizedBox(height: Jarak.md),
                  _CatatanPrinter(),

                  if (_galat != null) ...[
                    const SizedBox(height: Jarak.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: context.aksen.bahaya,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _galat!,
                            style: context.teks.bodySmall?.copyWith(
                              color: context.aksen.bahaya,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Jarak.sm,
                0,
                Jarak.sm,
                Jarak.sm,
              ),
              child: TombolPil(
                label: 'Simpan',
                memproses: _menyimpan,
                onTekan: _menyimpan ? null : _simpan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sakelar extends StatelessWidget {
  const _Sakelar({
    required this.judul,
    required this.keterangan,
    required this.nilai,
    required this.onUbah,
  });

  final String judul;
  final String keterangan;
  final bool nilai;
  final ValueChanged<bool> onUbah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Jarak.xs,
        vertical: Jarak.xs3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: context.teks.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  keterangan,
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
          Switch(value: nilai, onChanged: onUbah),
        ],
      ),
    );
  }
}

class _CatatanPrinter extends StatelessWidget {
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
            Icons.print_outlined,
            size: 20,
            color: context.warna.onSurfaceVariant,
          ),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              'Penyambungan printer Bluetooth menyusul. Sampai saat itu, '
              'struk bisa dilihat di Laporan · Riwayat dan dibagikan dari sana.',
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

// ---------------------------------------------------------------------------
// Pratinjau struk
// ---------------------------------------------------------------------------

/// Struk contoh yang mengikuti pengaturan.
///
/// Lebarnya sebanding dengan lebar kertas aslinya, jadi memilih 58 mm benar-
/// benar terlihat lebih sempit — bukan sekadar label yang berubah. Isinya
/// memakai barang dan angka yang wajar, karena yang menguji apakah baris muat
/// adalah "Kopi Susu Gula Aren", bukan "Item A".
class PratinjauStruk extends StatelessWidget {
  const PratinjauStruk({
    super.key,
    required this.toko,
    required this.pengaturan,
  });

  final Toko toko;
  final PengaturanStruk pengaturan;

  static const _baris = <(String, int, int)>[
    ('Kopi Susu Gula Aren', 2, 18000),
    ('Pisang Goreng', 1, 12000),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _baris.fold(0, (n, b) => n + b.$2 * b.$3);
    final gaya = context.teks.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'monospace'],
      height: 1.5,
    );
    final redup = gaya?.copyWith(color: context.warna.onSurfaceVariant);

    return Center(
      child: AnimatedContainer(
        duration: Gerak.sedang,
        curve: Gerak.keluar,
        width: pengaturan.lebar.lebarPratinjau,
        padding: const EdgeInsets.symmetric(
          horizontal: Jarak.xs,
          vertical: Jarak.sm,
        ),
        decoration: BoxDecoration(
          color: context.warna.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(Lengkung.kecil),
          border: Border.all(color: context.warna.outline),
          boxShadow: context.aksen.bayanganKartu,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              toko.nama.toUpperCase(),
              textAlign: TextAlign.center,
              style: gaya?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (pengaturan.tampilkanAlamat)
              Text(toko.alamat, textAlign: TextAlign.center, style: redup),
            if (pengaturan.tampilkanTelepon)
              Text(toko.telepon, textAlign: TextAlign.center, style: redup),
            if (pengaturan.kepala.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                pengaturan.kepala,
                textAlign: TextAlign.center,
                style: redup,
              ),
            ],

            const _Putus(),
            for (final (nama, jumlah, harga) in _baris) ...[
              Text(
                nama,
                style: gaya,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('  $jumlah x ${angka(harga)}', style: redup),
                  ),
                  Text(angka(jumlah * harga), style: gaya),
                ],
              ),
            ],
            const _Putus(),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'TOTAL',
                    style: gaya?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  angka(total),
                  style: gaya?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('TUNAI', style: redup)),
                Text(angka(50000), style: redup),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('KEMBALI', style: redup)),
                Text(angka(50000 - total), style: redup),
              ],
            ),

            if (pengaturan.tampilkanNamaKasir) ...[
              const SizedBox(height: 4),
              Text('Kasir: Bintang', style: redup),
            ],

            if (pengaturan.kaki.isNotEmpty) ...[
              const _Putus(),
              Text(pengaturan.kaki, textAlign: TextAlign.center, style: redup),
            ],
          ],
        ),
      ),
    );
  }
}

/// Garis putus-putus struk. `Divider` tidak punya bentuk ini, dan di struk
/// sungguhan justru garis inilah yang memisahkan rincian dari total.
class _Putus extends StatelessWidget {
  const _Putus();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, batas) {
          final jumlah = (batas.maxWidth / 6).floor().clamp(1, 200);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              jumlah,
              (_) => SizedBox(
                width: 3,
                height: 1,
                child: ColoredBox(color: context.warna.outline),
              ),
            ),
          );
        },
      ),
    );
  }
}
