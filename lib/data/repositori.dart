/// Lapisan data.
///
/// **Kontraknya: tidak ada satu pun layar yang menyentuh `contoh.dart`
/// langsung.** Semua lewat sini, semuanya `Future`, semuanya berjeda. Itu yang
/// membuat keadaan memuat / kosong / error benar-benar teruji sekarang —
/// bukan baru ketahuan setelah backend disambung dan ternyata belum pernah
/// ada tempatnya di tata letak (PRD §8).
///
/// Saat backend siap, isi berkas ini berubah jadi panggilan HTTP. Tanda
/// tangan fungsinya tidak berubah, jadi layar tidak ikut disentuh.
library;

import 'package:flutter/foundation.dart';

import 'contoh.dart';
import 'model.dart';

// ---------------------------------------------------------------------------
// Bentuk pemuatan
// ---------------------------------------------------------------------------

/// Tiga varian, empat keadaan.
///
/// "Kosong" sengaja BUKAN varian tersendiri: kosong adalah sifat datanya, dan
/// hanya pemanggil yang tahu apa artinya kosong untuk layarnya. Daftar produk
/// kosong berarti "belum ada produk"; daftar transaksi kosong hari ini berarti
/// "belum ada penjualan" — dua kalimat berbeda dari satu bentuk data yang sama.
sealed class Muatan<T> {
  const Muatan();
}

final class Memuat<T> extends Muatan<T> {
  const Memuat();
}

final class Galat<T> extends Muatan<T> {
  const Galat(this.pesan);
  final String pesan;
}

final class Siap<T> extends Muatan<T> {
  const Siap(this.data);
  final T data;
}

// ---------------------------------------------------------------------------
// Sakelar peragaan
// ---------------------------------------------------------------------------

/// Memaksa lapisan ini mengembalikan keadaan tertentu.
///
/// Ada supaya keempat keadaan bisa DILIHAT, bukan cuma dipercaya ada. Keadaan
/// kosong dan error yang tidak pernah dibuka adalah keadaan yang tidak pernah
/// benar-benar dirancang.
enum ModeUji { normal, memuat, kosong, galat }

final modeUji = ValueNotifier<ModeUji>(ModeUji.normal);

/// Bertambah setiap kali lapisan ini berubah dari dalam aplikasi — untuk
/// sekarang hanya saat pembayaran lunas.
///
/// [Bingkai] mendengarkannya, jadi setiap layar yang sedang terbuka memuat
/// ulang dirinya sendiri. Tanpa ini, layar Akun masih menampilkan "5 hari
/// lagi" tepat setelah pembayaran berhasil — dan tidak ada kabar buruk yang
/// lebih merusak kepercayaan daripada aplikasi yang tidak mengakui uang yang
/// baru saja dibayarkan.
///
/// Ini juga persis tempat state management masuk nanti. Satu notifier untuk
/// seluruh aplikasi jelas kasar; yang penting sekarang, seamnya cuma satu.
final revisiData = ValueNotifier<int>(0);

/// Jeda buatan 300–800 ms, sama seperti panel web. Cukup untuk melihat rangka
/// pemuatan, cukup pendek untuk tidak menjengkelkan saat dipakai.
Future<void> _jeda() =>
    Future<void>.delayed(Duration(milliseconds: 300 + _acakJeda()));

int _acakJeda() => DateTime.now().microsecond % 500;

Future<T> _kirim<T>(T Function() bangun, {required T kalauKosong}) async {
  switch (modeUji.value) {
    case ModeUji.memuat:
      // Sepuluh detik, bukan selamanya: cukup lama untuk diperiksa, cukup
      // pendek untuk tidak menggantung tes atau menyandera pengguna.
      await Future<void>.delayed(const Duration(seconds: 10));
      return bangun();
    case ModeUji.galat:
      await _jeda();
      throw const GagalMuat('Tidak bisa terhubung ke server.');
    case ModeUji.kosong:
      await _jeda();
      return kalauKosong;
    case ModeUji.normal:
      await _jeda();
      return bangun();
  }
}

class GagalMuat implements Exception {
  const GagalMuat(this.pesan);
  final String pesan;

  @override
  String toString() => pesan;
}

// ---------------------------------------------------------------------------
// Bentuk gabungan untuk Beranda
// ---------------------------------------------------------------------------

class RingkasanBeranda {
  const RingkasanBeranda({
    required this.omzet,
    required this.omzetKemarin,
    required this.transaksi,
    required this.item,
    required this.tujuhHari,
    required this.terakhir,
    required this.langganan,
    required this.produkHabis,
    required this.produkMenipis,
  });

  final int omzet;
  final int omzetKemarin;
  final int transaksi;
  final int item;

  /// Tujuh hari terakhir, terlama di depan, hari ini di belakang. Dipakai
  /// sebagai garis percikan di panel fokus.
  final List<int> tujuhHari;

  final List<Transaksi> terakhir;
  final Langganan langganan;
  final int produkHabis;
  final int produkMenipis;

  bool get belumAdaPenjualan => transaksi == 0;
  bool get adaMasalahStok => produkHabis > 0 || produkMenipis > 0;

  /// Selisih persen terhadap kemarin, atau **null** kalau kemarin nol.
  ///
  /// Null itu penting: pertumbuhan dari nol bukan "naik 100%", itu tidak
  /// terdefinisi. Menampilkan angka apa pun di situ adalah mengarang.
  int? get selisihPersen {
    if (omzetKemarin == 0) return null;
    return (((omzet - omzetKemarin) / omzetKemarin) * 100).round();
  }
}

// ---------------------------------------------------------------------------
// Repositori
// ---------------------------------------------------------------------------

abstract final class Repositori {
  static bool _samaHari(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Future<List<Kategori>> kategori() =>
      _kirim(() => kategoriContoh, kalauKosong: const []);

  static Future<List<Produk>> produk() =>
      _kirim(() => produkContoh, kalauKosong: const []);

  static Future<List<Ebook>> ebook() =>
      _kirim(() => ebookContoh, kalauKosong: const []);

  static Future<Langganan> langganan() =>
      _kirim(() => langgananContoh, kalauKosong: langgananContoh);

  static Future<RingkasanBeranda> beranda() => _kirim(
    () {
      final kini = DateTime.now();
      final awalHari = DateTime(kini.year, kini.month, kini.day);

      int omzetPada(DateTime hari) => transaksiContoh
          .where((t) => t.dihitung && _samaHari(t.waktu, hari))
          .fold(0, (n, t) => n + t.total);

      final hariIni = transaksiContoh
          .where((t) => t.dihitung && _samaHari(t.waktu, kini))
          .toList();

      return RingkasanBeranda(
        omzet: hariIni.fold(0, (n, t) => n + t.total),
        omzetKemarin: omzetPada(awalHari.subtract(const Duration(days: 1))),
        transaksi: hariIni.length,
        item: hariIni.fold(0, (n, t) => n + t.jumlahItem),
        tujuhHari: [
          for (var i = 6; i >= 0; i--)
            omzetPada(awalHari.subtract(Duration(days: i))),
        ],
        terakhir: transaksiContoh.take(4).toList(),
        langganan: langgananContoh,
        produkHabis: produkContoh.where((p) => p.habis).length,
        produkMenipis: produkContoh.where((p) => p.menipis).length,
      );
    },
    kalauKosong: RingkasanBeranda(
      omzet: 0,
      omzetKemarin: 0,
      transaksi: 0,
      item: 0,
      tujuhHari: const [0, 0, 0, 0, 0, 0, 0],
      terakhir: const [],
      langganan: langgananContoh,
      produkHabis: 0,
      produkMenipis: 0,
    ),
  );

  // -------------------------------------------------------------------------
  // Pembayaran langganan
  //
  // Saat Midtrans disambung, ketiga fungsi ini yang berubah isinya:
  // `buatTagihan` memanggil Snap/Core API, `periksaTagihan` membaca status
  // transaksi, dan status sungguhannya datang lewat webhook — bukan lewat
  // pengguna menekan "Saya sudah bayar". Tanda tangannya tidak berubah.
  // -------------------------------------------------------------------------

  static Future<List<Tagihan>> riwayatTagihan() =>
      _kirim(() => tagihanContoh, kalauKosong: const []);

  /// Membuat tagihan baru berstatus menunggu.
  ///
  /// Nomor VA-nya dibangkitkan di sini hanya untuk tahap tampilan. Nanti ia
  /// datang dari Midtrans, dan **tidak boleh** dibangkitkan di sisi aplikasi —
  /// nomor VA yang dikarang klien adalah nomor yang tidak akan pernah dibayar.
  ///
  /// Sengaja tidak lewat `_kirim`: membuat tagihan tidak punya bentuk
  /// "kosong" yang masuk akal, dan memaksakan satu ke sana justru
  /// menyembunyikan kesalahan.
  static Future<Tagihan> buatTagihan({
    required DurasiPaket durasi,
    required SaluranBayar saluran,
  }) async {
    await _jeda();
    if (modeUji.value == ModeUji.galat) {
      throw const GagalMuat('Tidak bisa membuat tagihan. Coba lagi.');
    }

    final kini = DateTime.now();
    final nomor = tagihanContoh.length + 32;
    return Tagihan(
      id: 'inv$nomor',
      nomorInvoice: 'INV/2026/${nomor.toString().padLeft(4, '0')}',
      durasi: durasi,
      nominal: durasi.harga,
      saluran: saluran,
      status: StatusBayar.menunggu,
      dibuat: kini,
      batasBayar: kini.add(const Duration(hours: 24)),
      berlakuSampai: langgananContoh.berakhirSetelahPerpanjang(durasi),
      kodeBayar: saluran.pakaiKode ? '8808 0812 3456 7890' : null,
    );
  }

  /// Memeriksa status tagihan ke gateway.
  ///
  /// Di tahap tampilan ia menjawab "lunas" — yang diuji di sini bukan gerbang
  /// pembayarannya, melainkan apakah layar sesudahnya benar: langganan
  /// bertambah, riwayat bertambah, dan seluruh aplikasi ikut memperbarui diri.
  ///
  /// Mode uji "kosong" mengembalikan tagihan apa adanya — itu bukan kelalaian,
  /// melainkan tiruan keadaan yang paling sering terjadi sungguhan: pengguna
  /// menekan "Saya sudah bayar" sebelum dananya benar-benar masuk.
  static Future<Tagihan> periksaTagihan(Tagihan tagihan) => _kirim(() {
    if (tagihan.lewatBatas) {
      return tagihan.salin(status: StatusBayar.kedaluwarsa);
    }

    final lunas = tagihan.salin(status: StatusBayar.lunas);
    langgananContoh = Langganan(
      durasi: tagihan.durasi,
      // Masa aktif lama tetap jadi titik mulai catatan ini, supaya bilah
      // kemajuan di Akun tidak melompat mundur setelah pembayaran.
      tanggalMulai: langgananContoh.menyambung
          ? langgananContoh.tanggalMulai
          : DateTime.now(),
      tanggalBerakhir: tagihan.berlakuSampai,
    );
    tagihanContoh = [lunas, ...tagihanContoh];
    revisiData.value++;
    return lunas;
  }, kalauKosong: tagihan);

  /// Riwayat, boleh disaring. Penyaringan dikerjakan DI SINI, bukan di layar —
  /// supaya saat penyaringan pindah ke sisi server nanti, layarnya tidak ikut
  /// diubah.
  static Future<List<Transaksi>> riwayat({
    String cari = '',
    StatusTransaksi? status,
    MetodeBayar? metode,
  }) => _kirim(() {
    final kunci = cari.trim().toLowerCase();
    return transaksiContoh.where((t) {
      if (status != null && t.status != status) return false;
      if (metode != null && t.metode != metode) return false;
      if (kunci.isEmpty) return true;
      return t.nomorStruk.toLowerCase().contains(kunci) ||
          t.baris.any((b) => b.nama.toLowerCase().contains(kunci));
    }).toList();
  }, kalauKosong: const []);

  /// Laporan penjualan (PRD §1). Seluruh angkanya DITURUNKAN dari transaksi —
  /// tidak ada satu pun yang dikarang, dan itu sengaja: laporan yang angkanya
  /// ditulis tangan tidak pernah ketahuan salah sampai dipakai sungguhan.
  static Future<Laporan> laporan(Periode periode) => _kirim(
    () {
      final kini = DateTime.now();
      final hariIni = DateTime(kini.year, kini.month, kini.day);
      final mulai = hariIni.subtract(Duration(days: periode.hari - 1));

      final dalam = transaksiContoh
          .where((t) => t.dihitung && !t.waktu.isBefore(mulai))
          .toList();

      // Deret harian selalu selengkap periodenya, termasuk hari-hari nol. Grafik
      // yang melompati hari sepi diam-diam membuat toko terlihat lebih ramai
      // daripada aslinya.
      final harian = <TitikHarian>[];
      for (var i = periode.hari - 1; i >= 0; i--) {
        final hari = hariIni.subtract(Duration(days: i));
        final isi = dalam.where((t) => _samaHari(t.waktu, hari));
        harian.add(
          TitikHarian(
            tanggal: hari,
            omzet: isi.fold(0, (n, t) => n + t.total),
            transaksi: isi.length,
          ),
        );
      }

      final perProduk = <String, ({int jumlah, int omzet})>{};
      for (final t in dalam) {
        for (final b in t.baris) {
          final l = perProduk[b.nama] ?? (jumlah: 0, omzet: 0);
          perProduk[b.nama] = (
            jumlah: l.jumlah + b.jumlah,
            omzet: l.omzet + b.subtotal,
          );
        }
      }
      final terlaris =
          perProduk.entries
              .map(
                (e) => ProdukTerlaris(
                  nama: e.key,
                  jumlah: e.value.jumlah,
                  omzet: e.value.omzet,
                ),
              )
              .toList()
            ..sort((a, b) => b.jumlah.compareTo(a.jumlah));

      final perMetode = <MetodeBayar, ({int omzet, int transaksi})>{};
      for (final t in dalam) {
        final l = perMetode[t.metode] ?? (omzet: 0, transaksi: 0);
        perMetode[t.metode] = (
          omzet: l.omzet + t.total,
          transaksi: l.transaksi + 1,
        );
      }
      final metode =
          MetodeBayar.values
              .map(
                (m) => PorsiMetode(
                  metode: m,
                  omzet: perMetode[m]?.omzet ?? 0,
                  transaksi: perMetode[m]?.transaksi ?? 0,
                ),
              )
              .where((p) => p.transaksi > 0)
              .toList()
            ..sort((a, b) => b.omzet.compareTo(a.omzet));

      return Laporan(
        periode: periode,
        omzet: dalam.fold(0, (n, t) => n + t.total),
        transaksi: dalam.length,
        item: dalam.fold(0, (n, t) => n + t.jumlahItem),
        harian: harian,
        terlaris: terlaris.take(5).toList(),
        metode: metode,
      );
    },
    kalauKosong: Laporan(
      periode: periode,
      omzet: 0,
      transaksi: 0,
      item: 0,
      harian: const [],
      terlaris: const [],
      metode: const [],
    ),
  );
}
