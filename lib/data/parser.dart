/// Parsing JSON dari backend ke model Dart.
///
/// Terpisah dari `model.dart` agar model tetap plain — tidak ada import
/// `dart:convert` di sana, dan tidak ada logika parsing di layar.
///
/// Setiap fungsi memetakan JSON response dari Resource Laravel yang
/// bersesuaian. Nama field mengikuti camelCase dari Resource, bukan
/// snake_case dari database.
library;

import 'package:flutter/material.dart' show IconData, Icons;

import 'model.dart';
import 'repositori.dart' show RingkasanBeranda;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DateTime _tanggal(dynamic v) {
  if (v == null) return DateTime.now();
  return DateTime.parse(v.toString());
}

int _int(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

double _double(dynamic v) =>
    v is double ? v : double.tryParse(v.toString()) ?? 0.0;

bool _bool(dynamic v) => v == true || v == 1 || v == '1';

// ---------------------------------------------------------------------------
// Kategori (← KategoriResource)
// ---------------------------------------------------------------------------

/// Peta nama ikon Material → IconData. Daftar yang sama dengan
/// `IkonKategori` di backend dan `ikonKategoriPilihan` di model.dart.
const _ikonDariNama = <String, IconData>{
  'coffee_outlined': Icons.coffee_outlined,
  'local_drink_outlined': Icons.local_drink_outlined,
  'local_cafe_outlined': Icons.local_cafe_outlined,
  'emoji_food_beverage_outlined': Icons.emoji_food_beverage_outlined,
  'wine_bar_outlined': Icons.wine_bar_outlined,
  'ramen_dining_outlined': Icons.ramen_dining_outlined,
  'rice_bowl_outlined': Icons.rice_bowl_outlined,
  'lunch_dining_outlined': Icons.lunch_dining_outlined,
  'local_pizza_outlined': Icons.local_pizza_outlined,
  'set_meal_outlined': Icons.set_meal_outlined,
  'bakery_dining_outlined': Icons.bakery_dining_outlined,
  'cake_outlined': Icons.cake_outlined,
  'icecream_outlined': Icons.icecream_outlined,
  'cookie_outlined': Icons.cookie_outlined,
  'egg_alt_outlined': Icons.egg_alt_outlined,
  'local_grocery_store_outlined': Icons.local_grocery_store_outlined,
  'soap_outlined': Icons.soap_outlined,
  'category_outlined': Icons.category_outlined,
};

/// Balik dari IconData ke nama string, untuk dikirim ke backend.
String ikonKeNama(IconData ikon) {
  for (final e in _ikonDariNama.entries) {
    if (e.value == ikon) return e.key;
  }
  return 'category_outlined';
}

Kategori kategoriDariJson(Map<String, dynamic> j) => Kategori(
  id: j['id'].toString(),
  nama: j['nama'] as String? ?? '',
  ikon: _ikonDariNama[j['ikon']] ?? Icons.category_outlined,
);

// ---------------------------------------------------------------------------
// Produk (← ProdukResource)
// ---------------------------------------------------------------------------

Produk produkDariJson(Map<String, dynamic> j) => Produk(
  id: j['id'].toString(),
  nama: j['nama'] as String? ?? '',
  kategoriId: j['kategoriId'].toString(),
  hargaJual: _int(j['hargaJual']),
  satuan: j['satuan'] as String? ?? 'pcs',
  lacakStok: _bool(j['lacakStok']),
  stok: _int(j['stok']),
  gambarUrl: j['gambarUrl'] as String?,
);

// ---------------------------------------------------------------------------
// Transaksi (← TransaksiResource)
// ---------------------------------------------------------------------------

BarisStruk _barisDariJson(Map<String, dynamic> j) => BarisStruk(
  produkId: (j['produkId'] ?? '').toString(),
  nama: j['nama'] as String? ?? '',
  hargaSatuan: _int(j['hargaSatuan']),
  jumlah: _int(j['jumlah']),
);

StatusTransaksi _statusTransaksi(String? v) => switch (v) {
  'SELESAI' => StatusTransaksi.selesai,
  'DITAHAN' => StatusTransaksi.ditahan,
  'BATAL' => StatusTransaksi.batal,
  _ => StatusTransaksi.selesai,
};

MetodeBayar _metodeBayar(String? v) => switch (v) {
  'TUNAI' => MetodeBayar.tunai,
  'QRIS' => MetodeBayar.qris,
  'TRANSFER' => MetodeBayar.transfer,
  _ => MetodeBayar.tunai,
};

Transaksi transaksiDariJson(Map<String, dynamic> j) => Transaksi(
  id: j['id'].toString(),
  nomorStruk: j['nomorStruk'] as String? ?? '',
  waktu: _tanggal(j['waktu']),
  baris: (j['baris'] as List<dynamic>?)
          ?.map((b) => _barisDariJson(b as Map<String, dynamic>))
          .toList() ??
      [],
  metode: _metodeBayar(j['metode'] as String?),
  status: _statusTransaksi(j['status'] as String?),
  pelanggan: j['pelanggan'] as String?,
  uangDiterima: j['uangDiterima'] as int?,
);

// ---------------------------------------------------------------------------
// Toko (← TokoResource)
// ---------------------------------------------------------------------------

Toko tokoDariJson(Map<String, dynamic> j) => Toko(
  nama: j['nama'] as String? ?? '',
  jenisUsaha: j['jenisUsahaLabel'] as String? ?? j['jenisUsaha'] as String? ?? '',
  alamat: j['alamat'] as String? ?? '',
  telepon: j['telepon'] as String? ?? '',
);

// ---------------------------------------------------------------------------
// Profil (← ProfilResource)
// ---------------------------------------------------------------------------

Profil profilDariJson(Map<String, dynamic> j) => Profil(
  nama: j['nama'] as String? ?? '',
  email: j['email'] as String? ?? '',
  telepon: j['telepon'] as String? ?? '',
  peran: j['peran'] as String? ?? 'Pemilik',
);

// ---------------------------------------------------------------------------
// Langganan (← LanggananTokoResource)
// ---------------------------------------------------------------------------

DurasiPaket _durasiPaket(String? v) => switch (v) {
  'BULANAN' => DurasiPaket.bulanan,
  'SEMESTERAN' => DurasiPaket.semesteran,
  'TAHUNAN' => DurasiPaket.tahunan,
  'TRIAL' => DurasiPaket.ujiCoba,
  _ => DurasiPaket.ujiCoba,
};

Langganan langgananDariJson(Map<String, dynamic> j) => Langganan(
  durasi: _durasiPaket(j['durasi'] as String?),
  tanggalMulai: _tanggal(j['tanggalMulai']),
  tanggalBerakhir: _tanggal(j['tanggalBerakhir']),
  ditangguhkan: _bool(j['ditangguhkan']),
);

// ---------------------------------------------------------------------------
// Pembayaran / Tagihan (← TagihanResource)
// ---------------------------------------------------------------------------

StatusBayar _statusBayar(String? v) => switch (v) {
  'LUNAS' => StatusBayar.lunas,
  'MENUNGGU' => StatusBayar.menunggu,
  'GAGAL' => StatusBayar.gagal,
  'KEDALUWARSA' => StatusBayar.kedaluwarsa,
  _ => StatusBayar.menunggu,
};

SaluranBayar _saluranBayar(String? v) => switch (v) {
  'QRIS' => SaluranBayar.qris,
  'VA_BCA' => SaluranBayar.vaBca,
  'VA_MANDIRI' => SaluranBayar.vaMandiri,
  'GOPAY' => SaluranBayar.gopay,
  _ => SaluranBayar.qris,
};

/// Nama enum saluran bayar untuk dikirim ke backend.
String saluranKeString(SaluranBayar s) => switch (s) {
  SaluranBayar.qris => 'QRIS',
  SaluranBayar.vaBca => 'VA_BCA',
  SaluranBayar.vaMandiri => 'VA_MANDIRI',
  SaluranBayar.gopay => 'GOPAY',
};

/// Nama enum durasi paket untuk dikirim ke backend.
String durasiKeString(DurasiPaket d) => switch (d) {
  DurasiPaket.ujiCoba => 'TRIAL',
  DurasiPaket.bulanan => 'BULANAN',
  DurasiPaket.semesteran => 'SEMESTERAN',
  DurasiPaket.tahunan => 'TAHUNAN',
};

Tagihan tagihanDariJson(Map<String, dynamic> j) => Tagihan(
  id: j['id'].toString(),
  nomorInvoice: j['nomorInvoice'] as String? ?? '',
  durasi: _durasiPaket(j['durasi'] as String?),
  nominal: _int(j['nominal']),
  saluran: _saluranBayar(j['saluran'] as String?),
  status: _statusBayar(j['status'] as String?),
  dibuat: _tanggal(j['dibuat']),
  batasBayar: _tanggal(j['batasBayar']),
  berlakuSampai: _tanggal(j['berlakuSampai']),
  kodeBayar: j['kodeBayar'] as String?,
);

// ---------------------------------------------------------------------------
// Ebook (← EbookPosResource)
// ---------------------------------------------------------------------------

Ebook ebookDariJson(Map<String, dynamic> j) => Ebook(
  id: j['id'].toString(),
  judul: j['judul'] as String? ?? '',
  kategori: j['kategoriLabel'] as String? ?? j['kategori'] as String? ?? '',
  deskripsi: j['deskripsi'] as String? ?? '',
  jumlahHalaman: _int(j['jumlahHalaman']),
  ukuranMb: _double(j['ukuranMb']),
  sudahDiunduh: _bool(j['bolehUnduh']),
);

// ---------------------------------------------------------------------------
// Pengaturan Struk (← PengaturanStrukResource)
// ---------------------------------------------------------------------------

LebarKertas _lebarKertas(String? v) => switch (v) {
  'MM58' => LebarKertas.mm58,
  'MM80' => LebarKertas.mm80,
  _ => LebarKertas.mm58,
};

PengaturanStruk pengaturanStrukDariJson(Map<String, dynamic> j) =>
    PengaturanStruk(
      kepala: j['kepala'] as String? ?? '',
      kaki: j['kaki'] as String? ?? '',
      tampilkanAlamat: _bool(j['tampilkanAlamat']),
      tampilkanTelepon: _bool(j['tampilkanTelepon']),
      tampilkanNamaKasir: _bool(j['tampilkanNamaKasir']),
      lebar: _lebarKertas(j['lebar'] as String?),
    );

// ---------------------------------------------------------------------------
// Beranda (← BerandaController)
// ---------------------------------------------------------------------------

RingkasanBeranda berandaDariJson(
  Map<String, dynamic> j,
  Langganan langganan,
) => RingkasanBeranda(
  omzet: _int(j['omzet']),
  omzetKemarin: _int(j['omzetKemarin']),
  transaksi: _int(j['transaksi']),
  item: _int(j['item']),
  tujuhHari: (j['tujuhHari'] as List<dynamic>?)
          ?.map((e) => _int(e))
          .toList() ??
      [0, 0, 0, 0, 0, 0, 0],
  terakhir: (j['terakhir'] as List<dynamic>?)
          ?.map((e) => transaksiDariJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  langganan: langganan,
  produkHabis: _int(j['produkHabis']),
  produkMenipis: _int(j['produkMenipis']),
  piutangJumlah: _int(j['piutangJumlah']),
  piutangTotal: _int(j['piutangTotal']),
);

// ---------------------------------------------------------------------------
// Laporan (← LaporanController)
// ---------------------------------------------------------------------------

Periode _periode(String? v) => switch (v) {
  'HARI_INI' => Periode.hariIni,
  'TUJUH_HARI' => Periode.tujuhHari,
  'TIGA_PULUH_HARI' => Periode.tigaPuluhHari,
  _ => Periode.hariIni,
};

/// Nama enum periode untuk dikirim ke backend.
String periodeKeString(Periode p) => switch (p) {
  Periode.hariIni => 'HARI_INI',
  Periode.tujuhHari => 'TUJUH_HARI',
  Periode.tigaPuluhHari => 'TIGA_PULUH_HARI',
};

Laporan laporanDariJson(Map<String, dynamic> j) => Laporan(
  periode: _periode(j['periode'] as String?),
  omzet: _int(j['omzet']),
  transaksi: _int(j['transaksi']),
  item: _int(j['item']),
  harian: (j['harian'] as List<dynamic>?)
          ?.map((e) {
            final m = e as Map<String, dynamic>;
            return TitikHarian(
              tanggal: _tanggal(m['tanggal']),
              omzet: _int(m['omzet']),
              transaksi: _int(m['transaksi']),
            );
          })
          .toList() ??
      [],
  terlaris: (j['terlaris'] as List<dynamic>?)
          ?.map((e) {
            final m = e as Map<String, dynamic>;
            return ProdukTerlaris(
              nama: m['nama'] as String? ?? '',
              jumlah: _int(m['jumlah']),
              omzet: _int(m['omzet']),
            );
          })
          .toList() ??
      [],
  metode: (j['metode'] as List<dynamic>?)
          ?.map((e) {
            final m = e as Map<String, dynamic>;
            return PorsiMetode(
              metode: _metodeBayar(m['metode'] as String?),
              omzet: _int(m['omzet']),
              transaksi: _int(m['transaksi']),
            );
          })
          .toList() ??
      [],
);
