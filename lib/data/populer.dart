/// Logika lencana "Terpopuler" — murni, tanpa widget.
///
/// Dipisah dari layarnya dengan alasan yang sama seperti `klaim.dart`:
/// `masuk()` di lapisan jaringan masih rusak, jadi tes widget alur tidak bisa
/// dipakai di proyek ini. Keputusan "siapa yang dapat lencana" karena itu
/// ditaruh di sini, dan layarnya tinggal menggambar.
library;

import 'model.dart';

/// Berapa konten yang boleh menyandang lencana "Terpopuler".
const batasTerpopuler = 3;

/// Id konten yang paling banyak dibuka — paling banyak [batasTerpopuler].
///
/// Peringkatnya dihitung di sini, bukan di server: katalognya memang dimuat
/// utuh (tanpa halaman), dan dua layar yang memakainya — Pustaka dan Klaim
/// gratis — harus menyebut pemenang yang sama. Kalau server yang menghitung
/// per jenis konten, dua daftar bisa berbeda pendapat.
///
/// Konten yang belum pernah dibuka tidak pernah masuk. Katalog yang masih
/// sepi tidak boleh melahirkan "Terpopuler" dari nol buka — lencana yang
/// diberikan tanpa dasar cepat kehilangan artinya, dan yang lebih buruk:
/// ia menandai konten yang justru belum ada yang membuka.
///
/// Seri diselesaikan oleh urutan [daftar], bukan oleh hasil `sort` — urutan
/// `sort` di Dart tidak dijamin stabil, dan pemenang seri yang berubah-ubah
/// antar pemuatan terbaca seperti angka yang rusak. Daftar datang dari server
/// sudah terurut (terbaru lebih dulu), jadi pemecah serinya pun tetap.
Set<String> idTerpopuler(List<Ebook> daftar) {
  final peringkat = <String, int>{
    for (var i = 0; i < daftar.length; i++) daftar[i].id: i,
  };

  final layak = [
    for (final ebook in daftar)
      if (ebook.jumlahUnduhan > 0) ebook,
  ]..sort((a, b) {
    final selisih = b.jumlahUnduhan.compareTo(a.jumlahUnduhan);
    if (selisih != 0) return selisih;

    return peringkat[a.id]!.compareTo(peringkat[b.id]!);
  });

  return {for (final ebook in layak.take(batasTerpopuler)) ebook.id};
}
