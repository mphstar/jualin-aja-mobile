import 'package:flutter/material.dart';

import '../data/repositori.dart';
import 'keadaan.dart';

/// Bentuk tampilan saat bingkai gagal memuat.
enum BentukGalat {
  /// Seluruh isi layar: halaman galat penuh, tanpa sisa isi tab mana pun.
  /// Dipakai di akar tab.
  halaman,

  /// Kartu di tengah halaman. Untuk bingkai yang berdiri sendiri.
  kartu,

  /// Satu baris. Untuk bagian layar yang bersebelahan dengan bagian lain.
  padat,
}

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
    this.bentukGalat = BentukGalat.kartu,
    this.pembungkusGalat,
  });

  final Future<T> Function() ambil;
  final Widget Function(BuildContext, T) isi;

  /// Ditampilkan selama memuat. Bentuknya harus menyerupai isi yang akan
  /// datang, bukan pemintal.
  final Widget rangka;

  /// Null berarti data ini tidak punya arti "kosong".
  final bool Function(T)? kosong;
  final Widget? saatKosong;

  /// Bentuk tampilan saat gagal memuat.
  ///
  /// Satu layar bisa memuat beberapa bingkai — layar Akun memuat empat. Bentuk
  /// kartu yang berulang ke bawah terbaca seperti sekian banyak masalah besar,
  /// padahal penyebabnya satu. Karena itu pemanggil menyatakan sendiri
  /// kedudukannya: akar tab memakai [BentukGalat.halaman] supaya seluruh
  /// halaman diganti satu tampilan galat, bagian di dalam halaman memakai
  /// [BentukGalat.padat], dan bingkai yang berdiri sendiri tetap
  /// [BentukGalat.kartu].
  final BentukGalat bentukGalat;

  /// Kerangka halaman untuk keadaan galat — judul, tepi, saringan.
  ///
  /// Dipakai supaya kepala halaman tetap tampil saat isinya gagal dimuat.
  /// Layar yang kehilangan judulnya terbaca seperti aplikasi yang rusak, bukan
  /// seperti koneksi yang sedang bermasalah. Kerangkanya sengaja hanya
  /// membungkus keadaan galat: keadaan memuat, kosong, dan siap sudah membawa
  /// kerangkanya sendiri.
  ///
  /// Untuk bingkai yang isinya hiasan belaka, `(_) => const SizedBox.shrink()`
  /// berarti "kalau gagal, tidak ada yang perlu dikatakan".
  final Widget Function(Widget galat)? pembungkusGalat;

  @override
  State<Bingkai<T>> createState() => BingkaiState<T>();
}

/// State [Bingkai] yang dipublikasikan agar tab bisa menarik-untuk-segar
/// (pull-to-refresh) dan memuat ulang data dari server.
class BingkaiState<T> extends State<Bingkai<T>> {
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

  /// Muat ulang lalu tunggu selesai — dipakai `RefreshIndicator.onRefresh`.
  ///
  /// Sengaja TIDAK menampilkan rangka (skeleton): menukar isi dengan rangka
  /// di tengah gestur justru melepas `RefreshIndicator` dari pohon widget dan
  /// menggagalkan animasinya. Isi lama tetap terlihat hingga data baru tiba.
  Future<void> muatUlangTunggu() async {
    if (!mounted) return;
    await _muat();
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
      Galat<T>(:final pesan) => _galat(pesan),
      Siap<T>(:final data) =>
        (widget.kosong?.call(data) ?? false) && widget.saatKosong != null
            ? widget.saatKosong!
            : widget.isi(context, data),
    };
  }

  /// Tampilan gagal, dengan kerangka halaman kalau pemanggil menyediakannya.
  Widget _galat(String pesan) {
    final galat = switch (widget.bentukGalat) {
      BentukGalat.halaman => Keadaan.galatHalaman(
        pesan: pesan,
        onCobaLagi: _muatUlang,
      ),
      BentukGalat.kartu => Keadaan.galat(
        pesan: pesan,
        onCobaLagi: _muatUlang,
      ),
      BentukGalat.padat => Keadaan.galatPadat(
        pesan: pesan,
        onCobaLagi: _muatUlang,
      ),
    };
    return widget.pembungkusGalat?.call(galat) ?? galat;
  }
}
