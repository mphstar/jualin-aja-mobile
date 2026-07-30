import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../data/sesi_kasir.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'kartu.dart';
import 'tombol_pil.dart';

/// Modal lembar bawah untuk Buka Kasir / Shift Baru.
class LembarBukaKasir extends StatefulWidget {
  const LembarBukaKasir({super.key, this.profilDefault});

  final Profil? profilDefault;

  static Future<SesiKasir?> tampilkan(
    BuildContext context, {
    Profil? profilDefault,
  }) {
    return showModalBottomSheet<SesiKasir>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => LembarBukaKasir(profilDefault: profilDefault),
    );
  }

  @override
  State<LembarBukaKasir> createState() => _LembarBukaKasirState();
}

class _LembarBukaKasirState extends State<LembarBukaKasir> {
  late final TextEditingController _nama;
  final _tunai = TextEditingController(text: '0');
  final _qris = TextEditingController(text: '0');
  final _transfer = TextEditingController(text: '0');

  bool _menyimpan = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(
      text: widget.profilDefault?.nama ?? 'Kasir',
    );
  }

  @override
  void dispose() {
    _nama.dispose();
    _tunai.dispose();
    _qris.dispose();
    _transfer.dispose();
    super.dispose();
  }

  int get _kasTunai => bacaNominal(_tunai.text);
  int get _kasQris => bacaNominal(_qris.text);
  int get _kasTransfer => bacaNominal(_transfer.text);
  int get _totalKasAwal => _kasTunai + _kasQris + _kasTransfer;

  Future<void> _buka() async {
    final namaKasir = _nama.text.trim();
    if (namaKasir.isEmpty) {
      setState(() => _galat = 'Nama kasir wajib diisi.');
      return;
    }

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      final sesi = await Repositori.bukaKasir(
        namaKasir: namaKasir,
        kasAwalTunai: _kasTunai,
        kasAwalQris: _kasQris,
        kasAwalTransfer: _kasTransfer,
      );

      if (!mounted) return;
      Navigator.of(context).pop(sesi);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Kasir dibuka oleh $namaKasir · Total Kas Awal: ${rupiah(_totalKasAwal)}',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Gagal membuka kasir: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tinggiMaks = MediaQuery.sizeOf(context).height * 0.85;

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
                      Icons.storefront_outlined,
                      size: 24,
                      color: context.warna.onSurface,
                    ),
                    const SizedBox(width: Jarak.xs2),
                    Expanded(
                      child: Text(
                        'Buka Kasir / Shift Baru',
                        style: context.teks.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Masukkan nama kasir bertugas dan kas awal per metode pembayaran.',
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Jarak.sm),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nama,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nama Kasir Bertugas',
                            hintText: 'Mis. Bintang / Kasir Pagi',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: Jarak.md),

                        const JudulBagian('Kas / Saldo Awal (Modal Shift)'),
                        KartuDaftar(
                          anak: [
                            Padding(
                              padding: const EdgeInsets.all(Jarak.xs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kas Awal Tunai',
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
                                  Text(
                                    'Kas Awal QRIS',
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
                                  Text(
                                    'Kas Awal Transfer',
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
                        const SizedBox(height: Jarak.sm),

                        Container(
                          padding: const EdgeInsets.all(Jarak.xs),
                          decoration: BoxDecoration(
                            color: context.aksen.kartuAlt,
                            borderRadius: BorderRadius.circular(Lengkung.kontrol),
                            border: Border.all(color: context.warna.outline),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL KAS AWAL',
                                style: context.teks.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                rupiah(_totalKasAwal),
                                style: context.teks.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                  label: 'Buka Kasir Sekarang',
                  memproses: _menyimpan,
                  onTekan: _menyimpan ? null : _buka,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
