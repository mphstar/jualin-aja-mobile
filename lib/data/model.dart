/// Model tampilan.
///
/// Sengaja hanya sebatas yang dibutuhkan layar — bukan cerminan penuh skema
/// basis data. Yang TIDAK boleh berbeda dari nanti adalah **aturannya**:
/// status langganan dihitung, bukan disimpan; total struk diturunkan dari
/// barisnya, bukan disimpan terpisah. Dua aturan itu disalin dari PRD §4.2 dan
/// §6, dan kalau backend menghitungnya berbeda, yang salah backend-nya.
library;

import 'package:flutter/widgets.dart' show IconData;

class Kategori {
  const Kategori({required this.id, required this.nama, required this.ikon});

  final String id;
  final String nama;

  /// Ikon untuk chip kategori bundar di layar kasir.
  final IconData ikon;
}

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
}

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
  });

  final String id;
  final String nomorStruk;
  final DateTime waktu;
  final List<BarisStruk> baris;
  final MetodeBayar metode;
  final StatusTransaksi status;

  /// Diturunkan, tidak disimpan. Total yang disimpan terpisah dari barisnya
  /// adalah dua sumber kebenaran, dan salah satunya pasti akan basi.
  int get total => baris.fold(0, (n, b) => n + b.subtotal);
  int get jumlahItem => baris.fold(0, (n, b) => n + b.jumlah);

  /// Hanya transaksi selesai yang dihitung sebagai omzet.
  bool get dihitung => status == StatusTransaksi.selesai;
}

class Ebook {
  const Ebook({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.deskripsi,
    required this.jumlahHalaman,
    required this.ukuranMb,
    this.sudahDiunduh = false,
  });

  final String id;
  final String judul;
  final String kategori;
  final String deskripsi;
  final int jumlahHalaman;
  final double ukuranMb;
  final bool sudahDiunduh;
}

// ---------------------------------------------------------------------------
// Langganan — aturan disalin dari PRD §4.1 dan §4.2
// ---------------------------------------------------------------------------

/// PRD §4.1. Satu paket, beda durasi — fiturnya identik di semua durasi.
enum DurasiPaket { ujiCoba, bulanan, semesteran, tahunan }

extension LabelDurasi on DurasiPaket {
  String get label => switch (this) {
    DurasiPaket.ujiCoba => 'Uji Coba 14 Hari',
    DurasiPaket.bulanan => '1 Bulan',
    DurasiPaket.semesteran => '6 Bulan',
    DurasiPaket.tahunan => '12 Bulan',
  };
}

enum StatusLangganan { ujiCoba, aktif, akanBerakhir, kedaluwarsa, nonaktif }

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

  /// PRD §4.3 — seluruh ebook terbit terbuka untuk langganan yang masih
  /// berjalan. Tidak ada pemberian akses per-ebook.
  bool get bolehUnduhResep =>
      status != StatusLangganan.kedaluwarsa &&
      status != StatusLangganan.nonaktif;
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
  });

  final DateTime tanggal;
  final int omzet;
  final int transaksi;
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
