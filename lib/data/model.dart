/// Model tampilan.
///
/// Sengaja hanya sebatas yang dibutuhkan layar — bukan cerminan penuh skema
/// basis data. Yang TIDAK boleh berbeda dari nanti adalah **aturannya**:
/// status langganan dihitung, bukan disimpan; total struk diturunkan dari
/// barisnya, bukan disimpan terpisah. Dua aturan itu disalin dari PRD §4.2 dan
/// §6, dan kalau backend menghitungnya berbeda, yang salah backend-nya.
library;

import 'package:flutter/material.dart' show IconData, Icons;

class Kategori {
  const Kategori({required this.id, required this.nama, required this.ikon});

  final String id;
  final String nama;

  /// Ikon untuk chip kategori bundar di layar kasir.
  final IconData ikon;

  Kategori salin({String? nama, IconData? ikon}) =>
      Kategori(id: id, nama: nama ?? this.nama, ikon: ikon ?? this.ikon);
}

/// Ikon yang boleh dipilih untuk kategori.
///
/// Daftar tertutup, sengaja. Membuka seluruh pustaka Material berarti memberi
/// pemilik toko dua ribu pilihan untuk satu keputusan yang tidak penting —
/// dan chip kasir yang isinya ikon "cloud" atau "settings" membuat barisnya
/// berhenti terbaca sebagai kategori makanan.
///
/// Urutannya mengikuti apa yang paling sering dijual warung: minuman dulu,
/// lalu makanan, lalu sisanya.
const ikonKategoriPilihan = <IconData>[
  Icons.coffee_outlined,
  Icons.local_drink_outlined,
  Icons.local_cafe_outlined,
  Icons.emoji_food_beverage_outlined,
  Icons.wine_bar_outlined,
  Icons.ramen_dining_outlined,
  Icons.rice_bowl_outlined,
  Icons.lunch_dining_outlined,
  Icons.local_pizza_outlined,
  Icons.set_meal_outlined,
  Icons.bakery_dining_outlined,
  Icons.cake_outlined,
  Icons.icecream_outlined,
  Icons.cookie_outlined,
  Icons.egg_alt_outlined,
  Icons.local_grocery_store_outlined,
  Icons.soap_outlined,
  Icons.category_outlined,
];

class Produk {
  const Produk({
    required this.id,
    required this.nama,
    required this.kategoriId,
    required this.hargaJual,
    required this.satuan,
    this.lacakStok = false,
    this.stok = 0,
    this.gambarUrl,
  });

  final String id;
  final String nama;
  final String kategoriId;
  final int hargaJual;
  final String satuan;
  final bool lacakStok;
  final int stok;

  /// Null selama pemilik toko belum mengunggah foto. `BlokFoto` menampilkan
  /// penanda bertulisan, bukan kotak kosong.
  final String? gambarUrl;

  bool get habis => lacakStok && stok <= 0;
  bool get menipis => lacakStok && stok > 0 && stok <= 5;

  Produk salin({
    String? nama,
    String? kategoriId,
    int? hargaJual,
    String? satuan,
    bool? lacakStok,
    int? stok,
  }) => Produk(
    id: id,
    nama: nama ?? this.nama,
    kategoriId: kategoriId ?? this.kategoriId,
    hargaJual: hargaJual ?? this.hargaJual,
    satuan: satuan ?? this.satuan,
    lacakStok: lacakStok ?? this.lacakStok,
    stok: stok ?? this.stok,
    gambarUrl: gambarUrl,
  );
}

/// Satuan yang lazim dipakai warung. Bukan daftar tertutup — formulir tetap
/// menerima ketikan bebas, ini cuma jalan pintas untuk yang paling sering.
const satuanUmum = <String>['pcs', 'porsi', 'gelas', 'cup', 'botol', 'bungkus'];

class ItemKeranjang {
  const ItemKeranjang({required this.produk, required this.jumlah});

  final Produk produk;
  final int jumlah;

  int get subtotal => produk.hargaJual * jumlah;
}

/// Satu baris di dalam struk.
///
/// Menyimpan nama dan harga sebagai SALINAN, bukan rujukan ke [Produk]. Kalau
/// pemilik toko menaikkan harga besok, struk kemarin harus tetap menunjukkan
/// harga kemarin — struk yang berubah sendiri bukan struk.
class BarisStruk {
  const BarisStruk({
    required this.produkId,
    required this.nama,
    required this.hargaSatuan,
    required this.jumlah,
  });

  final String produkId;
  final String nama;
  final int hargaSatuan;
  final int jumlah;

  int get subtotal => hargaSatuan * jumlah;
}

/// `ditahan` berarti barangnya sudah keluar tapi uangnya belum masuk —
/// "bayar nanti". Ia sengaja BUKAN status lunas: omzet hari itu tidak boleh
/// ikut naik hanya karena ada yang berjanji membayar besok.
enum StatusTransaksi { selesai, ditahan, batal }

enum MetodeBayar { tunai, qris, transfer }

extension LabelMetode on MetodeBayar {
  String get label => switch (this) {
    MetodeBayar.tunai => 'Tunai',
    MetodeBayar.qris => 'QRIS',
    MetodeBayar.transfer => 'Transfer',
  };
}

class Transaksi {
  const Transaksi({
    required this.id,
    required this.nomorStruk,
    required this.waktu,
    required this.baris,
    required this.metode,
    required this.status,
    this.pelanggan,
    this.uangDiterima,
    this.sesiId,
    this.namaKasir,
    this.subtotalRaw,
    this.diskonTipe,
    this.diskonNilai = 0,
    this.diskonNominal = 0,
  });

  final String id;
  final String nomorStruk;
  final DateTime waktu;
  final List<BarisStruk> baris;
  final MetodeBayar metode;
  final StatusTransaksi status;

  /// Siapa yang berutang. Hanya terisi untuk transaksi [StatusTransaksi.ditahan]
  /// — piutang tanpa nama adalah piutang yang tidak akan pernah ditagih.
  final String? pelanggan;

  /// Uang tunai yang diserahkan pembeli. Null untuk metode non-tunai.
  final int? uangDiterima;

  /// ID Sesi Shift Kasir dan Nama Kasir yang melayani transaksi.
  final String? sesiId;
  final String? namaKasir;

  /// Subtotal dan Data Diskon
  final int? subtotalRaw;
  final String? diskonTipe; // 'PERSEN' atau 'NOMINAL'
  final int diskonNilai;
  final int diskonNominal;

  int get subtotal => subtotalRaw ?? baris.fold(0, (n, b) => n + b.subtotal);
  int get total => (subtotal - diskonNominal).clamp(0, 999999999999);
  int get jumlahItem => baris.fold(0, (n, b) => n + b.jumlah);
  bool get adaDiskon => diskonNominal > 0;

  /// Kembalian, atau null kalau transaksi ini bukan tunai.
  int? get kembalian => uangDiterima == null ? null : uangDiterima! - total;

  /// Hanya transaksi selesai yang dihitung sebagai omzet.
  bool get dihitung => status == StatusTransaksi.selesai;

  /// Barang sudah keluar, uang belum masuk.
  bool get piutang => status == StatusTransaksi.ditahan;

  Transaksi salin({
    List<BarisStruk>? baris,
    MetodeBayar? metode,
    StatusTransaksi? status,
    int? uangDiterima,
    String? sesiId,
    String? namaKasir,
    int? subtotalRaw,
    String? diskonTipe,
    int? diskonNilai,
    int? diskonNominal,
  }) => Transaksi(
    id: id,
    nomorStruk: nomorStruk,
    waktu: waktu,
    baris: baris ?? this.baris,
    metode: metode ?? this.metode,
    status: status ?? this.status,
    pelanggan: pelanggan,
    uangDiterima: uangDiterima ?? this.uangDiterima,
    sesiId: sesiId ?? this.sesiId,
    namaKasir: namaKasir ?? this.namaKasir,
    subtotalRaw: subtotalRaw ?? this.subtotalRaw,
    diskonTipe: diskonTipe ?? this.diskonTipe,
    diskonNilai: diskonNilai ?? this.diskonNilai,
    diskonNominal: diskonNominal ?? this.diskonNominal,
  );
}

// ---------------------------------------------------------------------------
// Identitas toko & struk
// ---------------------------------------------------------------------------

/// Data toko yang tercetak di struk dan tampil di layar Akun.
class Toko {
  const Toko({
    required this.nama,
    required this.jenisUsaha,
    required this.alamat,
    required this.telepon,
  });

  final String nama;
  final String jenisUsaha;
  final String alamat;
  final String telepon;

  Toko salin({
    String? nama,
    String? jenisUsaha,
    String? alamat,
    String? telepon,
  }) => Toko(
    nama: nama ?? this.nama,
    jenisUsaha: jenisUsaha ?? this.jenisUsaha,
    alamat: alamat ?? this.alamat,
    telepon: telepon ?? this.telepon,
  );
}

/// Orang yang memakai aplikasi ini — bukan tokonya.
///
/// Sengaja terpisah dari [Toko]. Nama toko tercetak di struk dan dilihat
/// pembeli; nama pemilik tidak tercetak di mana pun dan hanya dipakai untuk
/// menyapa serta sebagai identitas masuk. Menyatukannya berarti mengganti
/// nomor telepon pribadi ikut mengubah nomor yang tercetak di struk.
class Profil {
  const Profil({
    required this.nama,
    required this.email,
    required this.telepon,
    this.peran = 'Pemilik',
  });

  final String nama;
  final String email;
  final String telepon;

  /// Belum bisa diubah dari aplikasi — akun pertama selalu pemilik. Ia ada di
  /// sini supaya layar tidak menuliskan "Pemilik" sebagai teks mati yang
  /// terlanjur benar hanya karena belum ada peran kedua.
  final String peran;

  Profil salin({String? nama, String? email, String? telepon}) => Profil(
    nama: nama ?? this.nama,
    email: email ?? this.email,
    telepon: telepon ?? this.telepon,
    peran: peran,
  );
}

/// Jenis usaha yang bisa dipilih. Nilainya adalah kode enum backend
/// (`KAFE`, `RESTORAN`, …), sama seperti yang dikirim saat pendaftaran, supaya
/// nilai yang sama bisa dikirim kembali ketika toko disunting.
const jenisUsahaPilihan = <String>[
  'KAFE',
  'RESTORAN',
  'WARUNG_MAKAN',
  'BAKERY',
  'TOKO_KELONTONG',
  'LAINNYA',
];

/// Label tampilan untuk tiap jenis usaha, mengikuti kode enum backend.
const jenisUsahaLabel = <String, String>{
  'KAFE': 'Kafe',
  'RESTORAN': 'Restoran',
  'WARUNG_MAKAN': 'Warung Makan',
  'BAKERY': 'Bakery',
  'TOKO_KELONTONG': 'Toko Kelontong',
  'LAINNYA': 'Lainnya',
};

/// Label tampilan untuk kode [value], atau [value] itu sendiri bila tak
/// dikenali (mis. data lama) supaya tidak tampak kosong.
String labelJenisUsaha(String value) => jenisUsahaLabel[value] ?? value;

/// Lebar kertas printer termal. Dua ukuran ini yang beredar; angkanya
/// menentukan berapa karakter yang muat per baris, jadi ia bukan sekadar
/// preferensi tampilan.
enum LebarKertas { mm58, mm80 }

extension RinciKertas on LebarKertas {
  String get label => switch (this) {
    LebarKertas.mm58 => '58 mm',
    LebarKertas.mm80 => '80 mm',
  };

  String get keterangan => switch (this) {
    LebarKertas.mm58 => 'Printer saku, 32 karakter per baris',
    LebarKertas.mm80 => 'Printer meja, 48 karakter per baris',
  };

  /// Lebar pratinjau di layar, sebanding dengan lebar kertas aslinya.
  double get lebarPratinjau => switch (this) {
    LebarKertas.mm58 => 210,
    LebarKertas.mm80 => 280,
  };
}

/// Apa yang dicetak di struk.
///
/// Kepala dan kaki struk dipisah dari data toko: nama dan alamat adalah FAKTA
/// toko, sedangkan "Terima kasih, sampai jumpa!" adalah pilihan penyajian.
/// Menyatukannya berarti mengubah sapaan menuntut menyunting identitas toko.
class PengaturanStruk {
  const PengaturanStruk({
    required this.kepala,
    required this.kaki,
    required this.tampilkanAlamat,
    required this.tampilkanTelepon,
    required this.tampilkanNamaKasir,
    required this.lebar,
  });

  final String kepala;
  final String kaki;
  final bool tampilkanAlamat;
  final bool tampilkanTelepon;
  final bool tampilkanNamaKasir;
  final LebarKertas lebar;

  PengaturanStruk salin({
    String? kepala,
    String? kaki,
    bool? tampilkanAlamat,
    bool? tampilkanTelepon,
    bool? tampilkanNamaKasir,
    LebarKertas? lebar,
  }) => PengaturanStruk(
    kepala: kepala ?? this.kepala,
    kaki: kaki ?? this.kaki,
    tampilkanAlamat: tampilkanAlamat ?? this.tampilkanAlamat,
    tampilkanTelepon: tampilkanTelepon ?? this.tampilkanTelepon,
    tampilkanNamaKasir: tampilkanNamaKasir ?? this.tampilkanNamaKasir,
    lebar: lebar ?? this.lebar,
  );
}

class Ebook {
  const Ebook({
    required this.id,
    required this.jenis,
    required this.judul,
    required this.kategori,
    required this.deskripsi,
    required this.jumlahHalaman,
    required this.ukuranMb,
    this.kategoriPrompt,
    this.coverUrl,
    this.fileUrl,
    this.bolehUnduh = false,
    this.harga = 25000,
    this.terbuka = false,
    this.statusAkses = 'TERKUNCI',
    this.bisaKlaim = false,
    this.jumlahUnduhan = 0,
  });

  final String id;
  final JenisKonten jenis;
  final String judul;
  final String kategori;
  final String? kategoriPrompt;
  final String deskripsi;
  final int jumlahHalaman;
  final double ukuranMb;

  /// URL gambar sampul yang diunggah admin; null kalau belum ada.
  final String? coverUrl;
  final String? fileUrl;
  final bool bolehUnduh;

  /// Harga beli satuan (rupiah).
  final int harga;

  /// Apakah konten sudah terbuka (klaim atau beli).
  final bool terbuka;

  /// Status akses: TERBUKA, BISA_KLAIM, atau TERKUNCI.
  final String statusAkses;

  /// Apakah jatah klaim untuk jenis ini masih tersedia.
  final bool bisaKlaim;

  /// Berapa kali konten ini dibuka, menurut server.
  ///
  /// Namanya `unduhan` mengikuti kolomnya di basis data, tapi yang dihitung
  /// adalah BUKA: endpoint yang sama dipakai aplikasi untuk membuka/pratinjau.
  /// Karena itu labelnya di layar harus "dibuka", bukan "diunduh".
  ///
  /// Nol berarti belum pernah ada yang membuka — bukan data yang tidak ada.
  final int jumlahUnduhan;

  String get labelKategori => jenis == JenisKonten.prompt
      ? (kategoriPrompt ?? 'Prompt')
      : kategori;
}

/// Jenis konten pustaka: resep masakan atau prompt (mis. untuk menghasilkan
/// gambar). Keduanya sama-sama PDF dan sama-sama bisa dilihat langsung di
/// aplikasi tanpa diunduh.
enum JenisKonten { resep, prompt }

// ---------------------------------------------------------------------------
// Langganan — aturan disalin dari PRD §4.1 dan §4.2
// ---------------------------------------------------------------------------

/// PRD §4.1. Satu paket, beda durasi — fiturnya identik di semua durasi.
/// Yang membedakan hanya lama berlangganan dan harga.
enum DurasiPaket { ujiCoba, bulanan, semesteran, tahunan }

/// Harga paket — diisi dari server saat layar Perpanjang dimuat.
///
/// Nilai di sini adalah bawaan awal yang dipakai sebelum server merespons.
/// Begitu [syncHargaDariServer] dipanggil, nilai-nilainya digantikan oleh
/// harga dari panel admin.
final hargaPaket = <DurasiPaket, int>{
  DurasiPaket.bulanan: 99000,
  DurasiPaket.semesteran: 499000,
  DurasiPaket.tahunan: 899000,
};

/// Perbarui [hargaPaket] dari array `harga` yang dikirim server.
void syncHargaDariServer(List<dynamic> daftarHarga) {
  for (final item in daftarHarga) {
    if (item is! Map) continue;
    final durasi = switch (item['durasi'] as String?) {
      'BULANAN' => DurasiPaket.bulanan,
      'SEMESTERAN' => DurasiPaket.semesteran,
      'TAHUNAN' => DurasiPaket.tahunan,
      _ => null,
    };
    if (durasi == null) continue;
    final h = item['harga'];
    if (h is int && h > 0) hargaPaket[durasi] = h;
  }
}

/// Yang boleh dibeli. Uji coba tidak ada di sini — ia diberikan otomatis saat
/// daftar, bukan dijual.
const paketDijual = <DurasiPaket>[
  DurasiPaket.bulanan,
  DurasiPaket.semesteran,
  DurasiPaket.tahunan,
];

extension LabelDurasi on DurasiPaket {
  String get label => switch (this) {
    DurasiPaket.ujiCoba => 'Uji Coba 14 Hari',
    DurasiPaket.bulanan => '1 Bulan',
    DurasiPaket.semesteran => '6 Bulan',
    DurasiPaket.tahunan => '12 Bulan',
  };

  int get bulan => switch (this) {
    DurasiPaket.ujiCoba => 0,
    DurasiPaket.bulanan => 1,
    DurasiPaket.semesteran => 6,
    DurasiPaket.tahunan => 12,
  };

  int get harga => hargaPaket[this] ?? 0;

  int get perBulan => bulan == 0 ? 0 : harga ~/ bulan;

  /// Hemat dibanding membeli bulanan berulang-ulang.
  ///
  /// **Dihitung, bukan angka pemasaran.** Kalau harganya diubah nanti, angka
  /// hematnya ikut berubah sendiri — klaim diskon yang ditulis tangan adalah
  /// klaim yang cepat atau lambat jadi bohong.
  int get hematPersen {
    final penuh = hargaPaket[DurasiPaket.bulanan]! * bulan;
    if (bulan <= 1 || penuh == 0) return 0;
    return ((penuh - harga) * 100 / penuh).round();
  }
}

/// Menambah bulan dengan menjepit tanggal ke hari terakhir bulan tujuan.
///
/// Tanpa penjepitan, 31 Januari + 1 bulan menghasilkan 3 Maret di Dart — dan
/// pelanggan yang membayar tanggal 31 akan kehilangan dua hari tanpa pernah
/// tahu kenapa.
DateTime tambahBulan(DateTime d, int bulan) {
  final total = d.month - 1 + bulan;
  final tahun = d.year + total ~/ 12;
  final bln = total % 12 + 1;
  final hariMaks = DateTime(tahun, bln + 1, 0).day;
  return DateTime(
    tahun,
    bln,
    d.day > hariMaks ? hariMaks : d.day,
    d.hour,
    d.minute,
  );
}

enum StatusLangganan { ujiCoba, aktif, akanBerakhir, kedaluwarsa, nonaktif }

/// 3 versi/tier paket langganan (Gratis, Trial, Langganan).
enum VersiLangganan { gratis, trial, langganan }

extension LabelVersi on VersiLangganan {
  String get label => switch (this) {
    VersiLangganan.gratis => 'Gratis',
    VersiLangganan.trial => 'Trial (Uji Coba)',
    VersiLangganan.langganan => 'Langganan (Aktif)',
  };
}

/// Sumber kebenaran TUNGGAL untuk hak akses & batasan fitur di Flutter mobile.
abstract final class FiturLangganan {
  static const int batasProdukGratis = 5;

  static VersiLangganan versiDariStatus(StatusLangganan status) {
    return switch (status) {
      StatusLangganan.ujiCoba => VersiLangganan.trial,
      StatusLangganan.aktif || StatusLangganan.akanBerakhir => VersiLangganan.langganan,
      StatusLangganan.kedaluwarsa || StatusLangganan.nonaktif => VersiLangganan.gratis,
    };
  }

  static bool bolehAksesResep(VersiLangganan versi) =>
      versi == VersiLangganan.langganan;

  static bool bolehAksesVoucher(VersiLangganan versi) =>
      versi != VersiLangganan.gratis;

  static bool bolehCustomKakiStruk(VersiLangganan versi) =>
      versi == VersiLangganan.langganan;

  static bool bolehTransaksi(VersiLangganan versi) => true;

  static int? batasMaksimalProduk(VersiLangganan versi) =>
      versi == VersiLangganan.gratis ? batasProdukGratis : null;

  static bool bolehTambahProduk(
    VersiLangganan versi,
    int jumlahProdukSaatIni, {
    int tambahan = 1,
  }) {
    final batas = batasMaksimalProduk(versi);
    if (batas == null) return true;
    return (jumlahProdukSaatIni + tambahan) <= batas;
  }
}

class Langganan {
  const Langganan({
    required this.durasi,
    required this.tanggalMulai,
    required this.tanggalBerakhir,
    this.ditangguhkan = false,
  });

  final DurasiPaket durasi;
  final DateTime tanggalMulai;
  final DateTime tanggalBerakhir;
  final bool ditangguhkan;

  /// Selisih KALENDER, bukan jam — supaya "berakhir hari ini" stabil berapa
  /// pun jam saat aplikasi dibuka.
  int get sisaHari {
    final kini = DateTime.now();
    final a = DateTime(kini.year, kini.month, kini.day);
    final b = DateTime(
      tanggalBerakhir.year,
      tanggalBerakhir.month,
      tanggalBerakhir.day,
    );
    return b.difference(a).inDays;
  }

  /// PRD §4.2 — status DIHITUNG dari tanggal, tidak pernah disimpan, sehingga
  /// tidak bisa basi. Urutan cabangnya penting: `ditangguhkan` menang atas
  /// segalanya, termasuk atas langganan yang secara tanggal masih aktif.
  StatusLangganan get status {
    if (ditangguhkan) return StatusLangganan.nonaktif;
    final sisa = sisaHari;
    if (sisa < 0) return StatusLangganan.kedaluwarsa;
    if (sisa <= 7) return StatusLangganan.akanBerakhir;
    if (durasi == DurasiPaket.ujiCoba) return StatusLangganan.ujiCoba;
    return StatusLangganan.aktif;
  }

  VersiLangganan get versi => FiturLangganan.versiDariStatus(status);

  /// Katalog Pustaka terbuka untuk semua akun (lihat saja). Akses per-konten
  /// diatur oleh endpoint klaim/beli.
  bool get bolehUnduhResep => true;

  /// Voucher/diskon transaksi terbuka untuk Trial dan Langganan.
  bool get bolehAksesVoucher => FiturLangganan.bolehAksesVoucher(versi);

  /// Kustomisasi teks kaki struk hanya terbuka untuk paket Berlangganan (Pro).
  bool get bolehCustomKakiStruk => FiturLangganan.bolehCustomKakiStruk(versi);

  /// Pencatatan transaksi terbuka untuk SEMUA versi, termasuk Gratis.
  bool get bolehTransaksi => FiturLangganan.bolehTransaksi(versi);

  /// Batas produk versi Gratis = 20, Trial/Langganan = null (unlimited).
  int? get batasMaksimalProduk => FiturLangganan.batasMaksimalProduk(versi);

  /// Apakah diperbolehkan menambah produk baru.
  bool bolehTambahProduk(int jumlahProdukSaatIni, {int tambahan = 1}) =>
      FiturLangganan.bolehTambahProduk(
        versi,
        jumlahProdukSaatIni,
        tambahan: tambahan,
      );

  /// PRD §4.4 — **sisa hari tidak hangus.**
  ///
  /// Perpanjangan menyambung dari [tanggalBerakhir] selama langganan masih
  /// berjalan, dan baru dihitung dari hari ini kalau sudah kedaluwarsa.
  /// Aturan ini wajib ditulis eksplisit di layar pembayaran: tanpa kalimat
  /// itu, orang menunda perpanjangan sampai hari terakhir karena mengira
  /// membayar lebih awal berarti membuang sisa harinya.
  DateTime berakhirSetelahPerpanjang(DurasiPaket durasi, {DateTime? sekarang}) {
    final kini = sekarang ?? DateTime.now();
    final dasar = tanggalBerakhir.isAfter(kini) ? tanggalBerakhir : kini;
    return tambahBulan(dasar, durasi.bulan);
  }

  /// True kalau perpanjangan menyambung sisa hari, bukan mulai dari nol.
  bool get menyambung => tanggalBerakhir.isAfter(DateTime.now());
}

// ---------------------------------------------------------------------------
// Pembayaran langganan (PRD §13 fase 3 — Mayar, native checkout)
// ---------------------------------------------------------------------------

/// PRD M6 F6.2.
enum StatusBayar { menunggu, lunas, gagal, kedaluwarsa }

extension LabelStatusBayar on StatusBayar {
  String get label => switch (this) {
    StatusBayar.menunggu => 'Menunggu pembayaran',
    StatusBayar.lunas => 'Lunas',
    StatusBayar.gagal => 'Gagal',
    StatusBayar.kedaluwarsa => 'Kedaluwarsa',
  };
}

/// Apa yang dibeli lewat tagihan ini — langganan atau satu konten Pustaka.
///
/// Dibutuhkan layar karena tagihan Pustaka memakai `durasi` placeholder
/// (kolomnya NOT NULL di server) dan `berlakuSampai` null. Tanpa pembeda ini
/// keduanya terbaca sebagai pembelian langganan satu bulan.
enum TipeTagihan { langganan, pustakaSatuan }

extension RinciTipeTagihan on TipeTagihan {
  bool get pustaka => this == TipeTagihan.pustakaSatuan;

  /// Judul baris rincian. Yang Pustaka menyebut konten, bukan paket.
  String get label => switch (this) {
    TipeTagihan.langganan => 'Langganan',
    TipeTagihan.pustakaSatuan => 'Pembelian konten',
  };
}

/// Kode `tipe` server → enum aplikasi. Null kalau tak dikenal, dan pemanggil
/// memperlakukannya sebagai langganan — nilai bawaan sebelum kolom ini ada.
TipeTagihan? tipeTagihanDariKode(String? kode) => switch (kode) {
  'LANGGANAN' => TipeTagihan.langganan,
  'PUSTAKA_SATUAN' => TipeTagihan.pustakaSatuan,
  _ => null,
};

/// Saluran pembayaran Mayar yang ditawarkan server.
enum SaluranBayar { qris }

extension RinciSaluran on SaluranBayar {
  String get label => switch (this) {
    SaluranBayar.qris => 'QRIS',
  };
}

/// Kode `paymentMethod` Mayar → enum aplikasi. Null kalau tak dikenal.
SaluranBayar? saluranDariKode(String? kode) => switch (kode) {
  'qris' => SaluranBayar.qris,
  _ => null,
};

/// Instrumen bayar native yang dinormalisasi backend (native checkout).
///
/// Hanya `qrString` yang terisi selama saluran cuma QRIS. Bentuknya harus
/// dianggap tak tepercaya: kalau tak dikenal, pemakaian jatuh ke
/// [Tagihan.tautanBayar].
class InstruksiBayar {
  const InstruksiBayar({
    this.qrString,
    this.kodeBayar,
    this.kodePerusahaan,
    this.aksi = const [],
  });

  /// Muatan QRIS mentah (`0002010102...`) yang digambar aplikasi sendiri.
  ///
  /// Sengaja string, bukan URL gambar: kode digambar di perangkat, sehingga
  /// muatan QRIS tidak pernah singgah di layanan pihak ketiga. Null kalau
  /// bukan QRIS.
  final String? qrString;

  /// Nomor Virtual Account (saluran VA). Null selama bukan VA.
  final String? kodeBayar;

  /// Kode perusahaan/bank (saluran VA). Null selama bukan VA.
  final String? kodePerusahaan;

  /// Daftar aksi e-wallet yang sudah lolos saringan skema URL.
  final List<AksiEwallet> aksi;
}

class AksiEwallet {
  const AksiEwallet({required this.url});

  final String url;
}

/// Satu tagihan langganan. Bentuknya mengikuti PRD §6 `Pembayaran`.
class Tagihan {
  const Tagihan({
    required this.id,
    required this.nomorInvoice,
    required this.tipe,
    required this.durasi,
    required this.nominal,
    required this.saluran,
    required this.status,
    required this.dibuat,
    required this.batasBayar,
    this.berlakuSampai,
    this.batasSaluran,
    this.instruksi,
    this.tautanBayar,
  });

  final String id;
  final String nomorInvoice;

  /// Tagihan langganan atau pembelian satuan konten Pustaka.
  final TipeTagihan tipe;

  /// Paket yang diperpanjang. Untuk tagihan Pustaka ini placeholder dari
  /// server dan tidak boleh ditampilkan — pakai [tipe] untuk memutuskan.
  final DurasiPaket durasi;

  final int nominal;
  final SaluranBayar? saluran;
  final StatusBayar status;
  final DateTime dibuat;

  /// Batas yang dipakai layar: kedaluwarsa saluran (bisa lebih awal dari
  /// invoice) atau kedaluwarsa invoice.
  final DateTime batasBayar;

  /// Kedaluwarsa saluran. Menang atas [batasBayar] kalau lebih awal.
  final DateTime? batasSaluran;

  /// Tanggal berakhir langganan SETELAH tagihan ini lunas. Dihitung saat
  /// tagihan dibuat, bukan saat dibayar — supaya angka yang dijanjikan di
  /// layar pembayaran sama persis dengan yang didapat.
  ///
  /// Null untuk pembelian konten Pustaka: yang dibeli akses permanen, bukan
  /// masa berlaku. Layar wajib memeriksa null sebelum menampilkannya.
  final DateTime? berlakuSampai;

  /// Instrumen native (QR/VA/e-wallet) untuk digambar langsung di aplikasi.
  final InstruksiBayar? instruksi;

  /// URL halaman hosted Mayar. Cadangan yang dipakai ketika [instruksi] null.
  final String? tautanBayar;

  Duration get sisaWaktu => batasBayar.difference(DateTime.now());
  bool get lewatBatas => sisaWaktu.isNegative;

  /// Status yang sudah memperhitungkan batas waktu. Tagihan yang lewat batas
  /// tapi masih tercatat "menunggu" adalah tagihan yang berbohong.
  StatusBayar get statusKini => status == StatusBayar.menunggu && lewatBatas
      ? StatusBayar.kedaluwarsa
      : status;

  Tagihan salin({StatusBayar? status}) => Tagihan(
    id: id,
    nomorInvoice: nomorInvoice,
    tipe: tipe,
    durasi: durasi,
    nominal: nominal,
    saluran: saluran,
    status: status ?? this.status,
    dibuat: dibuat,
    batasBayar: batasBayar,
    batasSaluran: batasSaluran,
    berlakuSampai: berlakuSampai,
    instruksi: instruksi,
    tautanBayar: tautanBayar,
  );
}

// ---------------------------------------------------------------------------
// Bentuk turunan untuk Laporan (PRD §1 — "laporan")
// ---------------------------------------------------------------------------

enum Periode { hariIni, tujuhHari, tigaPuluhHari }

extension LabelPeriode on Periode {
  String get label => switch (this) {
    Periode.hariIni => 'Hari ini',
    Periode.tujuhHari => '7 hari',
    Periode.tigaPuluhHari => '30 hari',
  };

  int get hari => switch (this) {
    Periode.hariIni => 1,
    Periode.tujuhHari => 7,
    Periode.tigaPuluhHari => 30,
  };
}

class TitikHarian {
  const TitikHarian({
    required this.tanggal,
    required this.omzet,
    required this.transaksi,
    this.label,
  });

  final DateTime tanggal;
  final int omzet;
  final int transaksi;
  final String? label;
}

class ProdukTerlaris {
  const ProdukTerlaris({
    required this.nama,
    required this.jumlah,
    required this.omzet,
  });

  final String nama;
  final int jumlah;
  final int omzet;
}

class PorsiMetode {
  const PorsiMetode({
    required this.metode,
    required this.omzet,
    required this.transaksi,
  });

  final MetodeBayar metode;
  final int omzet;
  final int transaksi;
}

/// Seluruh isi layar Laporan dalam satu bentuk.
///
/// Digabung jadi satu supaya layar itu punya SATU keadaan pemuatan, bukan
/// lima yang selesai bergantian dan membuat halaman berkedut empat kali.
class Laporan {
  const Laporan({
    required this.periode,
    required this.omzet,
    required this.transaksi,
    required this.item,
    required this.harian,
    required this.terlaris,
    required this.metode,
  });

  final Periode periode;
  final int omzet;
  final int transaksi;
  final int item;
  final List<TitikHarian> harian;
  final List<ProdukTerlaris> terlaris;
  final List<PorsiMetode> metode;

  /// Rata-rata per struk. Nol transaksi berarti nol, bukan pembagian dengan
  /// nol — keadaan yang benar-benar terjadi di hari pertama toko buka.
  int get rataPerStruk => transaksi == 0 ? 0 : omzet ~/ transaksi;

  bool get kosong => transaksi == 0;
}

// ---------------------------------------------------------------------------
// Model Ticketing & Support (Saran & Komplain)
// ---------------------------------------------------------------------------

enum JenisTiket {
  saran,
  komplain,
  pertanyaan;

  String get label {
    switch (this) {
      case JenisTiket.saran:
        return 'Saran Pengembangan';
      case JenisTiket.komplain:
        return 'Komplain / Bug';
      case JenisTiket.pertanyaan:
        return 'Pertanyaan Bantuan';
    }
  }

  static JenisTiket dariString(String v) {
    switch (v.toUpperCase()) {
      case 'SARAN':
        return JenisTiket.saran;
      case 'KOMPLAIN':
        return JenisTiket.komplain;
      default:
        return JenisTiket.pertanyaan;
    }
  }
}

enum StatusTiketTiketing {
  terbuka,
  diproses,
  selesai,
  ditutup;

  String get label {
    switch (this) {
      case StatusTiketTiketing.terbuka:
        return 'Terbuka';
      case StatusTiketTiketing.diproses:
        return 'Diproses';
      case StatusTiketTiketing.selesai:
        return 'Selesai';
      case StatusTiketTiketing.ditutup:
        return 'Ditutup';
    }
  }

  static StatusTiketTiketing dariString(String v) {
    switch (v.toUpperCase()) {
      case 'DIPROSES':
        return StatusTiketTiketing.diproses;
      case 'SELESAI':
        return StatusTiketTiketing.selesai;
      case 'DITUTUP':
        return StatusTiketTiketing.ditutup;
      default:
        return StatusTiketTiketing.terbuka;
    }
  }
}

class TiketDukungan {
  const TiketDukungan({
    required this.id,
    required this.nomorTiket,
    required this.jenis,
    required this.subjek,
    required this.pesan,
    required this.status,
    required this.dibuatPada,
    this.balasanAdmin,
    this.dibalasPada,
  });

  final int id;
  final String nomorTiket;
  final JenisTiket jenis;
  final String subjek;
  final String pesan;
  final StatusTiketTiketing status;
  final DateTime dibuatPada;
  final String? balasanAdmin;
  final DateTime? dibalasPada;
}
