/* Hallmark · redesign · genre: modern-minimal · sistem terkunci: design.md
 * varian: mobile-monokrom · aksi = tinta · kroma hanya status
 * pre-emit critique: P5 H5 E5 S5 R5 V4
 *
 * SATU-SATUNYA berkas tempat nilai warna mentah boleh ditulis.
 *
 * Nilainya dirancang di OKLCH lalu dikonversi ke sRGB, karena `Color` milik
 * Dart hanya mengenal sRGB. Rona netralnya ~75° dengan kroma 0.004–0.008 —
 * sangat rendah, tapi bukan nol. Abu berkroma nol terbaca dingin dan klinis di
 * bawah lampu warung; sedikit rona hangat membuat kertasnya terasa seperti
 * kertas, bukan seperti layar.
 */
library;

import 'package:flutter/widgets.dart';

/// Palet terang.
///
/// Tidak ada warna aksi di sini. Aksi utama memakai [tinta] — pekat, netral,
/// dan tidak pernah bersaing dengan status. Kroma hanya milik empat status,
/// dan itulah satu-satunya cara warna berarti sesuatu di aplikasi ini.
abstract final class WarnaTerang {
  // Permukaan
  static const kertas = Color(0xFFFCFAF7); // oklch(.985 .004 75)
  static const kartu = Color(0xFFFFFFFF);
  static const kartuAlt = Color(0xFFF5F1ED); // petak foto, panel dalam
  static const isian = Color(0xFFEFEBE6); // rangka pemuatan

  // Teks & garis
  static const tinta = Color(0xFF1A1512); // oklch(.20 .008 55)
  static const tintaRedup = Color(0xFF78706A); // oklch(.52 .008 65)
  static const garis = Color(0xFFE8E3DE);
  static const garisRedup = Color(0xFFF1EDE9);

  // Permukaan fokus — satu per layar. Di mode terang ia panel tinta di atas
  // kertas krem.
  static const fokus = Color(0xFF1A1512);
  static const atasFokus = Color(0xFFFAF8F6);
  static const atasFokusRedup = Color(0xFFA79F98);

  /// Isian tombol utama. Sengaja identik dengan [fokus]: kalau "penting"
  /// selalu tampil sebagai tinta, pengguna hanya perlu belajar satu sinyal.
  static const utama = fokus;
  static const atasUtama = atasFokus;

  // Status — satu-satunya kroma di seluruh aplikasi. Nilainya SAMA PERSIS
  // dengan panel web supaya "lunas" berwarna sama di kedua tempat.
  static const sukses = Color(0xFF009966);
  static const suksesLembut = Color(0xFFDEF3E9);
  static const peringatan = Color(0xFFE17100);
  static const peringatanLembut = Color(0xFFFBEEDA);
  static const bahaya = Color(0xFFE7000B);
  static const bahayaLembut = Color(0xFFFBE5E4);
  static const info = Color(0xFF1447E6);
  static const infoLembut = Color(0xFFE2E9FC);

  /// Teks di atas isian bahaya. Putih murni, bukan [atasFokus] yang kekrem —
  /// krem di atas merah terbaca kotor.
  static const atasBahaya = Color(0xFFFFFFFF);
  static const bayang = Color(0xFF1A1512);
}

/// Palet gelap. Bukan pembalikan otomatis — beberapa hubungan sengaja dibalik.
abstract final class WarnaGelap {
  static const kertas = Color(0xFF121110);
  static const kartu = Color(0xFF1C1A18);
  static const kartuAlt = Color(0xFF262320);
  static const isian = Color(0x1FFFFFFF); // putih 12%

  static const tinta = Color(0xFFF7F5F3);
  static const tintaRedup = Color(0xFFA69E97);
  static const garis = Color(0x17FFFFFF); // putih 9%
  static const garisRedup = Color(0x0FFFFFFF); // putih 6%

  /// Di mode gelap permukaan fokus justru LEBIH TERANG dari kertas. Memakai
  /// tinta yang sama akan membuatnya lenyap ke latar.
  static const fokus = Color(0xFF2A2724);
  static const atasFokus = Color(0xFFF7F5F3);
  static const atasFokusRedup = Color(0xFFA69E97);

  /// Tombol utama dibalik penuh: isian terang, teks gelap. Panel fokus tidak
  /// bisa ikut dibalik karena ia permukaan, bukan kontrol — makanya keduanya
  /// berbeda di sini, satu-satunya tempat mereka berpisah.
  static const utama = Color(0xFFF7F5F3);
  static const atasUtama = Color(0xFF121110);

  static const sukses = Color(0xFF00BC7D);
  static const suksesLembut = Color(0xFF0A3A28);
  static const peringatan = Color(0xFFFE9A00);
  static const peringatanLembut = Color(0xFF45300B);
  static const bahaya = Color(0xFFFF6467);
  static const bahayaLembut = Color(0xFF4E1F20);
  static const info = Color(0xFF66A1FF);
  static const infoLembut = Color(0xFF16305C);

  static const atasBahaya = Color(0xFF121110);
  static const bayang = Color(0xFF000000);
}

/// Radius bertingkat. Satu angka untuk semuanya tidak pernah pas: panel besar
/// butuh sudut yang lebih lapang daripada kontrol kecil, atau ia terlihat kaku.
abstract final class Lengkung {
  static const panel = 20.0;
  static const kontrol = 14.0;
  static const kecil = 10.0;
  static const bulat = 999.0;
}

/// Dua tingkat kedalaman, tidak lebih. Panel web tidak memakai bayangan sama
/// sekali; di ponsel ia dibutuhkan karena bilah keranjang dan lembar bawah
/// benar-benar mengambang di atas isi.
abstract final class Bayangan {
  static const kartu = <BoxShadow>[
    BoxShadow(color: Color(0x0D1A1512), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static const mengambang = <BoxShadow>[
    BoxShadow(color: Color(0x241A1512), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Skala jarak 4 pt, sama dengan panel web.
abstract final class Jarak {
  static const xs3 = 4.0;
  static const xs2 = 8.0;
  static const xs = 12.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 48.0;
}

/// Titik ubah tata letak. Tiga bentuk, bukan dua — tablet yang dipaksa memakai
/// bentuk ponsel membuang ruang, dan yang dipaksa memakai bentuk desktop
/// kehilangan setengah layar untuk rail.
abstract final class Ambang {
  static const ringkas = 600.0;
  static const luas = 1000.0;
}

abstract final class Gerak {
  static const cepat = Duration(milliseconds: 120);
  static const sedang = Duration(milliseconds: 200);
  static const lambat = Duration(milliseconds: 320);
  static const keluar = Curves.easeOutCubic;
  static const masuk = Curves.easeInCubic;
}

/// Figtree agak lapang secara bawaan; judul besar perlu dirapatkan atau ia
/// terbaca renggang. Aturan yang sama dengan panel web (-0.021em).
double kerapatanJudul(double ukuran) => ukuran * -0.021;
