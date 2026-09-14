/// Kegagalan menyimpan gambar ke galeri.
///
/// `pesan` sudah berbentuk kalimat yang aman ditampilkan ke pengguna: nama kelas
/// pengecualian platform maupun pesan mentahnya tidak pernah sampai ke layar
/// (bandingkan `_izinDitolak` di dialog impor produk, yang menetapkan aturan
/// yang sama).
///
/// Berkas ini sengaja tidak mengimpor apa pun supaya bisa dipakai ketiga varian
/// platform di [simpan_galeri.dart] — terutama varian web, yang tidak boleh
/// menyentuh `package:gal` sama sekali.
class GagalGaleri implements Exception {
  const GagalGaleri(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}
