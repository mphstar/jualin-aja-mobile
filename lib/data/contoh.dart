/// Data contoh untuk tahap tampilan.
///
/// **Deterministik.** Biji tetap ⇒ data yang sama di setiap muat ulang, jadi
/// tampilan bisa dibandingkan antar sesi dan angka di Beranda tidak berubah
/// tiap kali layar dibuka. Aturan yang sama dengan panel web (PRD §9.6).
///
/// Nama, harga, dan panjang teksnya sengaja realistis — tata letak harus
/// teruji oleh "Ayam Geprek Sambal Matah", bukan oleh "Item 1".
library;

import 'package:flutter/material.dart' show Icons;

import 'model.dart';

// ---------------------------------------------------------------------------
// Pembangkit acak deterministik (MINSTD)
// ---------------------------------------------------------------------------

/// Dipilih MINSTD, bukan mulberry32 seperti panel web, karena aplikasi ini
/// dikompilasi ke web juga — dan di sana `int` Dart adalah `double` JavaScript.
/// mulberry32 memakai perkalian 32×32 bit yang melewati 2^53 dan diam-diam
/// kehilangan presisi. Hasil kali MINSTD tidak pernah melewati 2^47.
class _Acak {
  _Acak(int biji) : _s = biji % 2147483647 {
    if (_s <= 0) _s += 2147483646;
  }

  int _s;

  double berikutnya() {
    _s = (_s * 48271) % 2147483647;
    return (_s - 1) / 2147483646;
  }

  int bilangan(int maksEksklusif) => (berikutnya() * maksEksklusif).floor();

  int antara(int min, int maks) => min + bilangan(maks - min + 1);

  T pilih<T>(List<T> daftar) => daftar[bilangan(daftar.length)];
}

// ---------------------------------------------------------------------------
// Identitas toko
// ---------------------------------------------------------------------------

const namaToko = 'Kopi Senja';
const namaPemilik = 'Bintang Pratama';
const emailPemilik = 'bintang@kopisenja.id';
const jenisUsaha = 'Kafe';
const kotaToko = 'Bandung';

/// Kredensial demo. Tahap tampilan belum punya autentikasi sungguhan, jadi
/// ditampilkan terang-terangan di layar masuk — bukan disembunyikan seolah
/// nyata.
const kredensialDemo = (email: 'bintang@kopisenja.id', sandi: 'kopisenja');

// ---------------------------------------------------------------------------
// Master data
// ---------------------------------------------------------------------------

const kategoriContoh = <Kategori>[
  Kategori(id: 'k1', nama: 'Kopi', ikon: Icons.coffee_outlined),
  Kategori(id: 'k2', nama: 'Non-Kopi', ikon: Icons.local_drink_outlined),
  Kategori(id: 'k3', nama: 'Makanan', ikon: Icons.ramen_dining_outlined),
  Kategori(id: 'k4', nama: 'Camilan', ikon: Icons.bakery_dining_outlined),
];

const produkContoh = <Produk>[
  Produk(
    id: 'p1',
    nama: 'Kopi Susu Gula Aren',
    kategoriId: 'k1',
    hargaJual: 18000,
    satuan: 'gelas',
  ),
  Produk(
    id: 'p2',
    nama: 'Americano',
    kategoriId: 'k1',
    hargaJual: 15000,
    satuan: 'gelas',
  ),
  Produk(
    id: 'p3',
    nama: 'Kopi Tubruk',
    kategoriId: 'k1',
    hargaJual: 10000,
    satuan: 'gelas',
  ),
  Produk(
    id: 'p4',
    nama: 'Cappuccino',
    kategoriId: 'k1',
    hargaJual: 22000,
    satuan: 'gelas',
  ),
  Produk(
    id: 'p5',
    nama: 'Matcha Latte',
    kategoriId: 'k2',
    hargaJual: 24000,
    satuan: 'gelas',
  ),
  Produk(
    id: 'p6',
    nama: 'Teh Tarik',
    kategoriId: 'k2',
    hargaJual: 14000,
    satuan: 'gelas',
  ),
  Produk(
    id: 'p7',
    nama: 'Cokelat Panas',
    kategoriId: 'k2',
    hargaJual: 20000,
    satuan: 'gelas',
  ),
  Produk(
    id: 'p8',
    nama: 'Nasi Goreng Kampung',
    kategoriId: 'k3',
    hargaJual: 25000,
    satuan: 'porsi',
    lacakStok: true,
    stok: 12,
  ),
  Produk(
    id: 'p9',
    nama: 'Mie Goreng Spesial',
    kategoriId: 'k3',
    hargaJual: 23000,
    satuan: 'porsi',
    lacakStok: true,
    stok: 4,
  ),
  Produk(
    id: 'p10',
    nama: 'Ayam Geprek Sambal Matah',
    kategoriId: 'k3',
    hargaJual: 28000,
    satuan: 'porsi',
    lacakStok: true,
    stok: 0,
  ),
  Produk(
    id: 'p11',
    nama: 'Pisang Goreng',
    kategoriId: 'k4',
    hargaJual: 12000,
    satuan: 'porsi',
    lacakStok: true,
    stok: 18,
  ),
  Produk(
    id: 'p12',
    nama: 'Roti Bakar Cokelat',
    kategoriId: 'k4',
    hargaJual: 16000,
    satuan: 'porsi',
  ),
];

/// Bobot popularitas per produk. Tanpa ini "produk terlaris" cuma mengurutkan
/// keacakan, dan urutannya akan terasa asal setiap kali dilihat.
const _bobot = <String, int>{
  'p1': 22, // kopi susu gula aren — pemenang yang jelas
  'p2': 11,
  'p3': 6,
  'p4': 9,
  'p5': 13,
  'p6': 7,
  'p7': 5,
  'p8': 12,
  'p9': 8,
  'p10': 4, // sedang habis, jadi jarang terjual
  'p11': 10,
  'p12': 5,
};

final _undianProduk = <Produk>[
  for (final p in produkContoh)
    for (var i = 0; i < (_bobot[p.id] ?? 1); i++) p,
];

// ---------------------------------------------------------------------------
// Transaksi — 30 hari ke belakang
// ---------------------------------------------------------------------------

/// Dibangkitkan sekali, dari hari terlama ke hari terbaru, supaya nomor
/// struknya menaik seperti di toko sungguhan.
final List<Transaksi> transaksiContoh = _bangkitkanTransaksi();

List<Transaksi> _bangkitkanTransaksi() {
  final acak = _Acak(20260726);
  final kini = DateTime.now();
  final hariIni = DateTime(kini.year, kini.month, kini.day);
  final hasil = <Transaksi>[];
  var nomor = 1;

  for (var mundur = 29; mundur >= 0; mundur--) {
    final tanggal = hariIni.subtract(Duration(days: mundur));

    // Akhir pekan lebih ramai. Bukan hiasan: laporan yang semua batangnya
    // sama tinggi tidak pernah menguji apakah grafiknya benar-benar berskala.
    final akhirPekan =
        tanggal.weekday == DateTime.saturday ||
        tanggal.weekday == DateTime.sunday;
    var cacah = akhirPekan ? acak.antara(11, 17) : acak.antara(5, 11);

    // Hari ini baru berjalan sebagian — transaksinya dipotong sesuai jam.
    // Tanpa ini, "penjualan hari ini" jam 8 pagi sudah menunjukkan omzet
    // sehari penuh, dan angka itu bohong.
    if (mundur == 0) {
      final porsiHari = ((kini.hour - 8) / 12).clamp(0.0, 1.0);
      cacah = (cacah * porsiHari).round();
    }

    for (var i = 0; i < cacah; i++) {
      // Jam buka 08:00–20:00, dan untuk hari ini tidak pernah melewati
      // jam sekarang.
      final jamMaks = mundur == 0 ? kini.hour.clamp(8, 20) : 20;
      if (jamMaks <= 8) continue;
      final waktu = tanggal.add(
        Duration(hours: acak.antara(8, jamMaks), minutes: acak.bilangan(60)),
      );
      if (waktu.isAfter(kini)) continue;

      // 1–4 baris, tanpa produk kembar dalam satu struk.
      final jumlahBaris = acak.antara(1, 4);
      final dipakai = <String>{};
      final baris = <BarisStruk>[];
      for (var b = 0; b < jumlahBaris; b++) {
        final p = acak.pilih(_undianProduk);
        if (!dipakai.add(p.id)) continue;
        baris.add(
          BarisStruk(
            produkId: p.id,
            nama: p.nama,
            hargaSatuan: p.hargaJual,
            jumlah: acak.antara(1, 3),
          ),
        );
      }
      if (baris.isEmpty) continue;

      final undi = acak.berikutnya();
      hasil.add(
        Transaksi(
          id: 't$nomor',
          nomorStruk: 'STR/2026/${nomor.toString().padLeft(4, '0')}',
          waktu: waktu,
          baris: baris,
          metode: undi < 0.55
              ? MetodeBayar.tunai
              : undi < 0.85
              ? MetodeBayar.qris
              : MetodeBayar.transfer,
          // ~4% batal. Angkanya kecil karena pembatalan memang jarang, dan
          // daftar yang setengahnya merah tidak mewakili toko mana pun.
          status: acak.berikutnya() < 0.04
              ? StatusTransaksi.batal
              : StatusTransaksi.selesai,
        ),
      );
      nomor++;
    }
  }

  // Terbaru di depan — urutan yang dipakai hampir semua layar.
  hasil.sort((a, b) => b.waktu.compareTo(a.waktu));
  return hasil;
}

// ---------------------------------------------------------------------------
// Katalog resep
// ---------------------------------------------------------------------------

const ebookContoh = <Ebook>[
  Ebook(
    id: 'e1',
    judul: '50 Resep Minuman Kekinian',
    kategori: 'Minuman',
    deskripsi:
        'Kopi susu gula aren, matcha latte, thai tea, hingga mocktail buah. '
        'Lengkap dengan takaran dan tips penyajian.',
    jumlahHalaman: 53,
    ukuranMb: 12.4,
    sudahDiunduh: true,
  ),
  Ebook(
    id: 'e2',
    judul: 'Racikan Kopi Manual Brew untuk Kafe',
    kategori: 'Minuman',
    deskripsi:
        'Panduan V60, Aeropress, dan tubruk dengan rasio air-kopi yang '
        'konsisten antar barista.',
    jumlahHalaman: 124,
    ukuranMb: 3.1,
  ),
  Ebook(
    id: 'e3',
    judul: 'Menu Andalan Warung Makan Laris',
    kategori: 'Makanan Berat',
    deskripsi:
        'Tiga puluh menu rumahan yang paling sering dipesan: ayam geprek, '
        'soto, rawon, dan lauk pendamping.',
    jumlahHalaman: 48,
    ukuranMb: 19.2,
  ),
  Ebook(
    id: 'e4',
    judul: 'Snack Gorengan Modal Kecil',
    kategori: 'Snack',
    deskripsi:
        'Resep gorengan dan camilan bermodal di bawah lima ribu rupiah '
        'per porsi.',
    jumlahHalaman: 121,
    ukuranMb: 11.0,
  ),
  Ebook(
    id: 'e5',
    judul: 'Bumbu Dasar Serbaguna',
    kategori: 'Bumbu & Saus',
    deskripsi:
        'Bumbu dasar merah, putih, dan kuning untuk puluhan menu — hemat '
        'waktu persiapan harian.',
    jumlahHalaman: 36,
    ukuranMb: 6.8,
    sudahDiunduh: true,
  ),
  Ebook(
    id: 'e6',
    judul: 'Dessert Box & Pudding Praktis',
    kategori: 'Dessert',
    deskripsi:
        'Dessert box, pudding, dan panna cotta yang tahan disimpan, cocok '
        'untuk pesanan pre-order.',
    jumlahHalaman: 131,
    ukuranMb: 24.0,
  ),
];

// ---------------------------------------------------------------------------
// Langganan
// ---------------------------------------------------------------------------

/// Sengaja disetel tersisa 5 hari supaya keadaan "akan berakhir" — yang paling
/// mudah dilupakan saat membangun — ikut terlihat sejak layar pertama dibuka.
final langgananContoh = Langganan(
  durasi: DurasiPaket.bulanan,
  tanggalMulai: DateTime.now().subtract(const Duration(days: 25)),
  tanggalBerakhir: DateTime.now().add(const Duration(days: 5)),
);
