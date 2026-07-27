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
      await Repositori.lunasiTransaksi(
        widget.transaksi,
        metode: _metode,
        uangDiterima: _tunai ? _diterima : null,
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

  @override
  Widget build(BuildContext context) {
    final t = widget.transaksi;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
          child: Column(
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
          ),
        ),
      ),
    );
  }
}
