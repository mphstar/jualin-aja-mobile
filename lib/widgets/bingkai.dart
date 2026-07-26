import 'package:flutter/material.dart';

import '../data/repositori.dart';
import 'keadaan.dart';

/// Pembungkus yang mengubah satu `Future` jadi **empat keadaan** di layar:
/// memuat · kosong · galat · normal (PRD §8).
///
/// Kenapa satu widget dan bukan `FutureBuilder` di tiap layar: karena kalau
/// tiap layar menuliskan percabangannya sendiri, cepat atau lambat ada yang
/// lupa menulis cabang kosong — dan itu selalu ketahuan di depan pengguna,
/// bukan saat membangun.
///
/// Ia juga ikut mendengarkan [modeUji] dan [revisiData], sehingga sakelar
/// peragaan di layar Akun — dan pembayaran yang baru saja lunas — langsung
/// memuat ulang setiap layar yang sedang terbuka.
class Bingkai<T> extends StatefulWidget {
  const Bingkai({
    super.key,
    required this.ambil,
    required this.isi,
    required this.rangka,
    this.kosong,
    this.saatKosong,
  });

  final Future<T> Function() ambil;
  final Widget Function(BuildContext, T) isi;

  /// Ditampilkan selama memuat. Bentuknya harus menyerupai isi yang akan
  /// datang, bukan pemintal.
  final Widget rangka;

  /// Null berarti data ini tidak punya arti "kosong".
  final bool Function(T)? kosong;
  final Widget? saatKosong;

  @override
  State<Bingkai<T>> createState() => _BingkaiState<T>();
}

class _BingkaiState<T> extends State<Bingkai<T>> {
  Muatan<T> _muatan = const Memuat();

  /// Penghitung generasi. Tanpa ini, jawaban dari permintaan lama yang datang
  /// terlambat bisa menimpa jawaban permintaan baru — bug yang cuma muncul
  /// saat jaringan lambat, yaitu justru saat paling sulit ditelusuri.
  int _generasi = 0;

  /// Satu langganan untuk dua sumber: sakelar peragaan dan perubahan data.
  late final Listenable _pemicu = Listenable.merge([modeUji, revisiData]);

  @override
  void initState() {
    super.initState();
    _pemicu.addListener(_muatUlang);
    _muat();
  }

  @override
  void dispose() {
    _pemicu.removeListener(_muatUlang);
    super.dispose();
  }

  void _muatUlang() {
    if (!mounted) return;
    setState(() => _muatan = const Memuat());
    _muat();
  }

  Future<void> _muat() async {
    final generasi = ++_generasi;
    try {
      final data = await widget.ambil();
      if (!mounted || generasi != _generasi) return;
      setState(() => _muatan = Siap(data));
    } on GagalMuat catch (e) {
      if (!mounted || generasi != _generasi) return;
      setState(() => _muatan = Galat(e.pesan));
    } catch (_) {
      if (!mounted || generasi != _generasi) return;
      setState(() => _muatan = const Galat('Terjadi kesalahan tak terduga.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_muatan) {
      Memuat<T>() => widget.rangka,
      Galat<T>(:final pesan) => Keadaan.galat(
        pesan: pesan,
        onCobaLagi: _muatUlang,
      ),
      Siap<T>(:final data) =>
        (widget.kosong?.call(data) ?? false) && widget.saatKosong != null
            ? widget.saatKosong!
            : widget.isi(context, data),
    };
  }
}
