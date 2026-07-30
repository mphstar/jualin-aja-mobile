import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../data/sesi_kasir.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../util/pencetak_struk.dart';
import 'kartu.dart';
import 'tombol_pil.dart';

/// Modal lembar bawah untuk Tutup Kasir / End Shift.
class LembarTutupKasir extends StatefulWidget {
  const LembarTutupKasir({super.key, required this.sesi});

  final SesiKasir sesi;

  static Future<SesiKasir?> tampilkan(
    BuildContext context, {
    required SesiKasir sesi,
  }) {
    return showModalBottomSheet<SesiKasir>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => LembarTutupKasir(sesi: sesi),
    );
  }

  @override
  State<LembarTutupKasir> createState() => _LembarTutupKasirState();
}

class _LembarTutupKasirState extends State<LembarTutupKasir> {
  late final TextEditingController _tunai;
  late final TextEditingController _qris;
  late final TextEditingController _transfer;
  final _catatan = TextEditingController();

  bool _menyimpan = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _tunai = TextEditingController(text: angka(widget.sesi.ekspektasiTunai));
    _qris = TextEditingController(text: angka(widget.sesi.ekspektasiQris));
    _transfer = TextEditingController(text: angka(widget.sesi.ekspektasiTransfer));
  }

  @override
  void dispose() {
    _tunai.dispose();
    _qris.dispose();
    _transfer.dispose();
    _catatan.dispose();
    super.dispose();
  }

  int get _kasFisikTunai => bacaNominal(_tunai.text);
  int get _kasFisikQris => bacaNominal(_qris.text);
  int get _kasFisikTransfer => bacaNominal(_transfer.text);

  int get _selisihTunai => _kasFisikTunai - widget.sesi.ekspektasiTunai;
  int get _selisihQris => _kasFisikQris - widget.sesi.ekspektasiQris;
  int get _selisihTransfer => _kasFisikTransfer - widget.sesi.ekspektasiTransfer;
  int get _totalSelisih => _selisihTunai + _selisihQris + _selisihTransfer;

  Future<void> _selesaikanTutupKasir({bool cetakStrukSetoran = true}) async {
    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      final ditutup = await Repositori.tutupKasir(
        kasFisikTunai: _kasFisikTunai,
        kasFisikQris: _kasFisikQris,
        kasFisikTransfer: _kasFisikTransfer,
        catatan: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
      );

      if (!mounted) return;
      final nav = Navigator.of(context);
      final me = ScaffoldMessenger.of(context);

      nav.pop(ditutup);

      if (cetakStrukSetoran) {
        try {
          final toko = await Repositori.toko();
          final pengaturan = await Repositori.pengaturanStruk();
          if (mounted) {
            await PencetakStruk.cetakLaporanShiftBluetooth(
              context,
              toko: toko,
              pengaturan: pengaturan,
              sesi: ditutup,
            );
          }
        } catch (_) {}
      }

      me
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Shift ${ditutup.namaKasir} ditutup · Total Setoran: ${rupiah(ditutup.totalKasFisik)}',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Gagal menutup kasir: $e';
      });
    }
  }

  Widget _labelSelisih(BuildContext context, int selisih) {
    if (selisih == 0) {
      return Text(
        'Pas (Rp 0)',
        style: context.teks.bodySmall?.copyWith(
          color: context.aksen.sukses,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (selisih < 0) {
      return Text(
        'Kurang (${rupiah(selisih)})',
        style: context.teks.bodySmall?.copyWith(
          color: context.aksen.bahaya,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        'Lebih (+${rupiah(selisih)})',
        style: context.teks.bodySmall?.copyWith(
          color: context.aksen.peringatan,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sesi;
    final tinggiMaks = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: tinggiMaks),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.no_encryption_gmailerrorred_outlined,
                      size: 24,
                      color: context.warna.onSurface,
                    ),
                    const SizedBox(width: Jarak.xs2),
                    Expanded(
                      child: Text('Tutup Kasir / End Shift', style: context.teks.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Kasir: ${s.namaKasir} · Dibatasi sejak ${jam(s.waktuBuka)} (${relatif(s.waktuBuka)})',
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Jarak.sm),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ringkasan Penjualan Shift
                        const JudulBagian('Ringkasan Penjualan Shift'),
                        KartuDaftar(
                          anak: [
                            BarisDaftar(
                              awalan: const Icon(Icons.receipt_long, size: 20),
                              judul: 'Jumlah Transaksi Selesai',
                              akhiran: '${s.jumlahTransaksi} transaksi',
                            ),
                            BarisDaftar(
                              awalan: const Icon(Icons.payments_outlined, size: 20),
                              judul: 'Penjualan Tunai',
                              keterangan: 'Modal awal: ${rupiah(s.kasAwalTunai)}',
                              akhiran: rupiah(s.totalTunai),
                            ),
                            BarisDaftar(
                              awalan: const Icon(Icons.qr_code_scanner, size: 20),
                              judul: 'Penjualan QRIS',
                              keterangan: 'Modal awal: ${rupiah(s.kasAwalQris)}',
                              akhiran: rupiah(s.totalQris),
                            ),
                            BarisDaftar(
                              awalan: const Icon(Icons.account_balance_outlined, size: 20),
                              judul: 'Penjualan Transfer',
                              keterangan: 'Modal awal: ${rupiah(s.kasAwalTransfer)}',
                              akhiran: rupiah(s.totalTransfer),
                            ),
                          ],
                        ),
                        const SizedBox(height: Jarak.md),

                        // Form Hitung Kas Fisik
                        const JudulBagian('Rekonsiliasi Kas Fisik / Aktual'),
                        KartuDaftar(
                          anak: [
                            Padding(
                              padding: const EdgeInsets.all(Jarak.xs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Hitung Kas Tunai Fisik',
                                        style: context.teks.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _labelSelisih(context, _selisihTunai),
                                    ],
                                  ),
                                  Text(
                                    'Ekspektasi: ${rupiah(s.ekspektasiTunai)}',
                                    style: context.teks.bodySmall?.copyWith(
                                      color: context.warna.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _tunai,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: false,
                                    ),
                                    inputFormatters: [FormatRibuan()],
                                    decoration: const InputDecoration(
                                      prefixText: 'Rp  ',
                                      hintText: '0',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(Jarak.xs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Hitung Fisik QRIS',
                                        style: context.teks.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _labelSelisih(context, _selisihQris),
                                    ],
                                  ),
                                  Text(
                                    'Ekspektasi: ${rupiah(s.ekspektasiQris)}',
                                    style: context.teks.bodySmall?.copyWith(
                                      color: context.warna.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _qris,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: false,
                                    ),
                                    inputFormatters: [FormatRibuan()],
                                    decoration: const InputDecoration(
                                      prefixText: 'Rp  ',
                                      hintText: '0',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(Jarak.xs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Hitung Fisik Transfer',
                                        style: context.teks.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _labelSelisih(context, _selisihTransfer),
                                    ],
                                  ),
                                  Text(
                                    'Ekspektasi: ${rupiah(s.ekspektasiTransfer)}',
                                    style: context.teks.bodySmall?.copyWith(
                                      color: context.warna.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _transfer,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: false,
                                    ),
                                    inputFormatters: [FormatRibuan()],
                                    decoration: const InputDecoration(
                                      prefixText: 'Rp  ',
                                      hintText: '0',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Jarak.xs2),

                        TextField(
                          controller: _catatan,
                          decoration: const InputDecoration(
                            labelText: 'Catatan Kasir (Opsional)',
                            hintText: 'Mis. Ada selisih karena kembalian kurang',
                          ),
                        ),
                        const SizedBox(height: Jarak.sm),

                        Container(
                          padding: const EdgeInsets.all(Jarak.xs),
                          decoration: BoxDecoration(
                            color: _totalSelisih == 0
                                ? context.aksen.sukses.withAlpha(20)
                                : context.aksen.bahaya.withAlpha(20),
                            borderRadius: BorderRadius.circular(Lengkung.kontrol),
                            border: Border.all(
                              color: _totalSelisih == 0
                                  ? context.aksen.sukses
                                  : context.aksen.bahaya,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL FISIK DITERIMA',
                                    style: context.teks.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    rupiah(_kasFisikTunai + _kasFisikQris + _kasFisikTransfer),
                                    style: context.teks.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL SELISIH KAS',
                                    style: context.teks.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _labelSelisih(context, _totalSelisih),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_galat != null) ...[
                  const SizedBox(height: Jarak.xs),
                  Text(
                    _galat!,
                    style: context.teks.bodySmall?.copyWith(
                      color: context.aksen.bahaya,
                    ),
                  ),
                ],

                const SizedBox(height: Jarak.md),
                TombolPil(
                  label: 'Tutup Kasir & Cetak Struk Setoran',
                  memproses: _menyimpan,
                  onTekan: _menyimpan
                      ? null
                      : () => _selesaikanTutupKasir(cetakStrukSetoran: true),
                ),
                const SizedBox(height: Jarak.xs2),
                TombolPilGaris(
                  label: 'Tutup Kasir Tanpa Cetak',
                  onTekan: _menyimpan
                      ? null
                      : () => _selesaikanTutupKasir(cetakStrukSetoran: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
