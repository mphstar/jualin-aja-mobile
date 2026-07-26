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
/// Yang membedakan hanya lama berlangganan dan harga.
enum DurasiPaket { ujiCoba, bulanan, semesteran, tahunan }

/// Harga paket. **Satu tempat, sengaja** — PRD §4.1 menandainya sebagai angka
/// contoh yang nanti bisa diubah dari halaman Pengaturan panel admin. Kalau ia
/// tersebar ke beberapa berkas, perubahan harga akan selalu menyisakan satu
/// tempat yang terlewat.
const hargaPaket = <DurasiPaket, int>{
  DurasiPaket.bulanan: 99000,
  DurasiPaket.semesteran: 499000,
  DurasiPaket.tahunan: 899000,
};

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
// Pembayaran langganan (PRD §13 fase 3 — Midtrans)
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

/// Saluran pembayaran Midtrans yang akan dipakai.
///
/// Daftarnya sengaja pendek. Midtrans menyediakan belasan saluran, tapi
/// halaman yang menawarkan belasan pilihan membuat orang berhenti memilih —
/// dan tiga saluran ini menutupi hampir semua pemilik toko di Indonesia.
enum SaluranBayar { qris, vaBca, vaMandiri, gopay }

enum GrupSaluran { qris, virtualAccount, eWallet }

extension RinciSaluran on SaluranBayar {
  String get label => switch (this) {
    SaluranBayar.qris => 'QRIS',
    SaluranBayar.vaBca => 'Virtual Account BCA',
    SaluranBayar.vaMandiri => 'Virtual Account Mandiri',
    SaluranBayar.gopay => 'GoPay',
  };

  String get keterangan => switch (this) {
    SaluranBayar.qris => 'Pindai dari aplikasi bank atau e-wallet mana pun',
    SaluranBayar.vaBca => 'Transfer ke nomor VA lewat m-BCA atau ATM',
    SaluranBayar.vaMandiri => 'Transfer ke nomor VA lewat Livin atau ATM',
    SaluranBayar.gopay => 'Bayar langsung dari saldo GoPay',
  };

  GrupSaluran get grup => switch (this) {
    SaluranBayar.qris => GrupSaluran.qris,
    SaluranBayar.vaBca || SaluranBayar.vaMandiri => GrupSaluran.virtualAccount,
    SaluranBayar.gopay => GrupSaluran.eWallet,
  };

  /// True kalau saluran ini memberi nomor yang harus disalin pelanggan.
  bool get pakaiKode => grup == GrupSaluran.virtualAccount;
}

/// Satu tagihan langganan. Bentuknya mengikuti PRD §6 `Pembayaran`.
class Tagihan {
  const Tagihan({
    required this.id,
    required this.nomorInvoice,
    required this.durasi,
    required this.nominal,
    required this.saluran,
    required this.status,
    required this.dibuat,
    required this.batasBayar,
    required this.berlakuSampai,
    this.kodeBayar,
  });

  final String id;
  final String nomorInvoice;
  final DurasiPaket durasi;
  final int nominal;
  final SaluranBayar saluran;
  final StatusBayar status;
  final DateTime dibuat;

  /// Midtrans menutup tagihan yang tidak dibayar. 24 jam adalah bawaan yang
  /// lazim, dan cukup longgar untuk orang yang membayar lewat ATM besok pagi.
  final DateTime batasBayar;

  /// Tanggal berakhir langganan SETELAH tagihan ini lunas. Dihitung saat
  /// tagihan dibuat, bukan saat dibayar — supaya angka yang dijanjikan di
  /// layar pembayaran sama persis dengan yang didapat.
  final DateTime berlakuSampai;

  /// Nomor Virtual Account. Null untuk saluran yang tidak memakainya.
  final String? kodeBayar;

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
    durasi: durasi,
    nominal: nominal,
    saluran: saluran,
    status: status ?? this.status,
    dibuat: dibuat,
    batasBayar: batasBayar,
    berlakuSampai: berlakuSampai,
    kodeBayar: kodeBayar,
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
