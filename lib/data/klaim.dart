/// Logika layar klaim Pustaka — murni, tanpa widget.
///
/// Dipisah dari layarnya supaya bisa diuji tanpa membangun pohon widget:
/// `masuk()` di lapisan jaringan masih rusak, jadi tes widget alur tidak bisa
/// dipakai di proyek ini. Semua keputusan layar klaim karena itu ditaruh di
/// sini, dan layarnya tinggal menggambar.
library;

import 'model.dart';

/// Keadaan jatah klaim satu jenis konten (Resep atau Prompt).
enum StatusJatah {
  /// Masih ada konten jenis ini yang bisa diklaim.
  tersedia,

  /// Jenis ini punya konten terbit, tapi jatahnya sudah dipakai siklus ini.
  terpakai,

  /// Jenis ini belum punya konten terbit sama sekali — bukan jatah yang habis.
  kosong,
}

/// Satu bagian layar klaim: satu jenis konten beserta isinya.
class BagianKlaim {
  const BagianKlaim({
    required this.jenis,
    required this.bisaDiklaim,
    required this.status,
  });

  final JenisKonten jenis;

  /// Konten jenis ini yang jatahnya masih tersedia. Kosong kalau [status]
  /// bukan [StatusJatah.tersedia].
  final List<Ebook> bisaDiklaim;

  final StatusJatah status;

  String get label => jenis == JenisKonten.prompt ? 'Prompt' : 'Resep';
}

/// Ringkasan jatah klaim — selalu dua bagian, urutannya tetap: Resep, Prompt.
class RingkasanKlaim {
  const RingkasanKlaim(this.bagian);

  final List<BagianKlaim> bagian;

  /// Berapa jenis yang jatahnya masih tersedia.
  int get jatahTersedia =>
      bagian.where((b) => b.status == StatusJatah.tersedia).length;

  /// Berapa jenis yang jatahnya sudah dipakai siklus langganan ini.
  int get jatahTerpakai =>
      bagian.where((b) => b.status == StatusJatah.terpakai).length;

  /// Label jenis yang jatahnya masih tersedia, urut tetap: Resep, Prompt.
  ///
  /// Dipakai banner Pustaka supaya kalimatnya jujur ketika tinggal satu jenis
  /// yang belum diklaim — "Resep & Prompt" untuk dua-duanya, "Prompt" saja
  /// kalau jatah Resep sudah dipakai.
  List<String> get labelTersedia => [
    for (final b in bagian)
      if (b.status == StatusJatah.tersedia) b.label,
  ];

  /// Tidak ada lagi yang bisa diklaim — entah jatahnya habis, entah kontennya
  /// memang belum ada.
  bool get selesai => jatahTersedia == 0;
}

/// Susun dua bagian klaim dari katalog yang dikirim server.
///
/// Sumber kebenarannya adalah `Ebook.statusAkses` yang sudah dihitung server
/// (`EbookPosResource`). Jenis yang punya konten terbit tapi TIDAK satu pun
/// bertanda `BISA_KLAIM` berarti jatahnya sudah dipakai; jenis tanpa konten
/// terbit bukan jatah habis, melainkan kosong. Itu yang membuat penghitung
/// "x dari 2 jatah terpakai" jujur, bukan tebakan dari sisi aplikasi.
///
/// Berlaku untuk akun berlangganan aktif — di luar itu server menandai
/// semuanya `TERKUNCI`, dan layar ini memang hanya dibuka setelah pembayaran
/// langganan berhasil.
RingkasanKlaim ringkasanKlaim(List<Ebook> daftar) {
  const urutan = [JenisKonten.resep, JenisKonten.prompt];

  return RingkasanKlaim([
    for (final jenis in urutan) _bagianUntuk(daftar, jenis),
  ]);
}

BagianKlaim _bagianUntuk(List<Ebook> daftar, JenisKonten jenis) {
  final sejenis = daftar.where((e) => e.jenis == jenis);
  final bisaDiklaim =
      sejenis.where((e) => e.statusAkses == 'BISA_KLAIM').toList();

  final StatusJatah status;
  if (sejenis.isEmpty) {
    status = StatusJatah.kosong;
  } else if (bisaDiklaim.isEmpty) {
    status = StatusJatah.terpakai;
  } else {
    status = StatusJatah.tersedia;
  }

  return BagianKlaim(jenis: jenis, bisaDiklaim: bisaDiklaim, status: status);
}

/// Apakah layar pembayaran lunas harus menawarkan jalan ke layar klaim.
///
/// Hanya tagihan **langganan** yang menawarkannya: tagihan Pustaka satuan
/// membuka satu konten tertentu, bukan jatah klaim, dan tawarannya justru akan
/// menyesatkan.
///
/// Ini cuma menentukan apakah tombolnya DIGAMBAR — berpindah atau tidak tetap
/// keputusan pengguna. Jatahnya sendiri hidup di server dan tidak ikut hangus
/// kalau tombolnya tidak ditekan, jadi tidak ada lagi pengalihan otomatis yang
/// harus dijaga dari pemeriksaan status berkala.
bool tawarkanKlaim(Tagihan tagihan) {
  if (tagihan.tipe != TipeTagihan.langganan) return false;

  return tagihan.statusKini == StatusBayar.lunas;
}
