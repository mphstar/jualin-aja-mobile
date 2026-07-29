/// Lapisan data — sekarang tersambung ke backend Laravel.
///
/// Tanda tangan fungsi TIDAK BERUBAH dari versi contoh. Layar-layar Flutter
/// tidak perlu diubah sama sekali. Yang berubah hanya isi fungsinya: dari
/// membaca `contoh.dart` menjadi panggilan HTTP ke `/api/mobile/v1/*`.
///
/// Keadaan memuat / kosong / error tetap sama — bedanya sekarang error
/// datang dari jaringan sungguhan, bukan dari sakelar peragaan.
library;

import 'package:flutter/foundation.dart';

import 'api.dart' as api;
import 'model.dart';
import 'parser.dart';

// ---------------------------------------------------------------------------
// Bentuk pemuatan (tidak berubah dari versi contoh)
// ---------------------------------------------------------------------------

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
// Sakelar peragaan — tetap ada untuk development
// ---------------------------------------------------------------------------

enum ModeUji { normal, memuat, kosong, galat }

final modeUji = ValueNotifier<ModeUji>(ModeUji.normal);

/// Bertambah setiap kali lapisan ini berubah dari dalam aplikasi.
final revisiData = ValueNotifier<int>(0);

class GagalMuat implements Exception {
  const GagalMuat(this.pesan);
  final String pesan;

  @override
  String toString() => pesan;
}

// ---------------------------------------------------------------------------
// Bentuk gabungan untuk Beranda (tidak berubah)
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
    required this.piutangJumlah,
    required this.piutangTotal,
  });

  final int omzet;
  final int omzetKemarin;
  final int transaksi;
  final int item;
  final List<int> tujuhHari;
  final List<Transaksi> terakhir;
  final Langganan langganan;
  final int produkHabis;
  final int produkMenipis;
  final int piutangJumlah;
  final int piutangTotal;

  bool get belumAdaPenjualan => transaksi == 0;
  bool get adaMasalahStok => produkHabis > 0 || produkMenipis > 0;
  bool get adaPiutang => piutangJumlah > 0;

  int? get selisihPersen {
    if (omzetKemarin == 0) return null;
    return (((omzet - omzetKemarin) / omzetKemarin) * 100).round();
  }
}

// ---------------------------------------------------------------------------
// Repositori — sekarang memanggil API backend
// ---------------------------------------------------------------------------

abstract final class Repositori {

  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------

  /// Pendaftaran mandiri toko baru. Mengembalikan data awal (profil, toko, langganan).
  static Future<({Profil profil, Toko toko, Langganan langganan})> daftar({
    required String nama,
    required String email,
    required String telepon,
    required String namaToko,
    required String jenisUsaha,
    required String kota,
    required String kataSandi,
    required String kataSandiKonfirmasi,
  }) async {
    final j = await api.post('/auth/daftar', {
      'nama': nama,
      'email': email,
      'telepon': telepon,
      'namaToko': namaToko,
      'jenisUsaha': jenisUsaha,
      'kota': kota,
      'kataSandi': kataSandi,
      'kataSandi_confirmation': kataSandiKonfirmasi,
      'perangkat': 'Aplikasi POS Flutter',
    });

    await api.simpanToken(j['token'] as String);

    final profil = profilDariJson(j['profil'] as Map<String, dynamic>);
    final toko = tokoDariJson(j['toko'] as Map<String, dynamic>);
    final langganan = langgananDariJson(
      j['langganan'] as Map<String, dynamic>,
    );

    return (profil: profil, toko: toko, langganan: langganan);
  }

  /// Login ke backend. Mengembalikan data awal (profil, toko, langganan).
  static Future<({Profil profil, Toko toko, Langganan langganan})> masuk({
    required String email,
    required String kataSandi,
  }) async {
    final j = await api.post('/auth/masuk', {
      'email': email,
      'kataSandi': kataSandi,
      'perangkat': 'Aplikasi POS Flutter',
    });

    await api.simpanToken(j['token'] as String);

    final profil = profilDariJson(j['profil'] as Map<String, dynamic>);
    final toko = tokoDariJson(j['toko'] as Map<String, dynamic>);
    final langganan = langgananDariJson(
      j['langganan'] as Map<String, dynamic>,
    );

    return (profil: profil, toko: toko, langganan: langganan);
  }

  /// Logout.
  static Future<void> keluar() async {
    try {
      await api.post('/auth/keluar');
    } catch (_) {
      // Kalau gagal, tetap hapus token lokal.
    }
    await api.hapusToken();
  }

  /// Cek sesi yang masih tersimpan.
  static Future<({Profil profil, Toko toko, Langganan langganan})?> cekSesi() async {
    await api.muatToken();
    if (!api.sudahMasuk) return null;

    try {
      final j = await api.get('/auth/saya');
      final profil = profilDariJson(j['profil'] as Map<String, dynamic>);
      final toko = tokoDariJson(j['toko'] as Map<String, dynamic>);
      final langganan = langgananDariJson(
        j['langganan'] as Map<String, dynamic>,
      );
      return (profil: profil, toko: toko, langganan: langganan);
    } on GagalMuat {
      // Token sudah tidak sah.
      await api.hapusToken();
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Master data
  // -------------------------------------------------------------------------

  static Future<List<Kategori>> kategori() async {
    final daftar = await api.getDaftar('/kategori');
    return daftar
        .map((e) => kategoriDariJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Produk>> produk() async {
    final daftar = await api.getDaftar('/produk');
    return daftar
        .map((e) => produkDariJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<({Uint8List bytes, String filename})> unduhFormatImporProduk() async {
    final hasil = await api.getBytes('/produk/format-impor');
    return (
      bytes: hasil.bytes,
      filename: hasil.filename ?? 'format_impor_produk.xlsx',
    );
  }

  static Future<({Uint8List bytes, String filename})> eksporProduk() async {
    final hasil = await api.getBytes('/produk/ekspor');
    return (
      bytes: hasil.bytes,
      filename: hasil.filename ?? 'data_produk.xlsx',
    );
  }

  static Future<Map<String, dynamic>> imporProduk(
    Uint8List bytes,
    String namaBerkas,
  ) async {
    final hasil = await api.uploadFile('/produk/impor', bytes, namaBerkas);
    revisiData.value++;
    return hasil;
  }

  static Future<List<Ebook>> ebook() async {
    final daftar = await api.getDaftar('/resep');
    return daftar
        .map((e) => ebookDariJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Langganan & pembayaran
  // -------------------------------------------------------------------------

  static Future<Langganan> langganan() async {
    final j = await api.get('/langganan');
    return langgananDariJson(j['langganan'] as Map<String, dynamic>);
  }

  static Future<List<Tagihan>> riwayatTagihan() async {
    final daftar = await api.getDaftar('/tagihan');
    return daftar
        .map((e) => tagihanDariJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Tagihan> buatTagihan({
    required DurasiPaket durasi,
    required SaluranBayar saluran,
  }) async {
    final j = await api.post('/tagihan', {
      'durasi': durasiKeString(durasi),
      'saluran': saluranKeString(saluran),
    });
    return tagihanDariJson(j);
  }

  static Future<Tagihan> periksaTagihan(Tagihan tagihan) async {
    final j = await api.post('/tagihan/${tagihan.id}/periksa');
    final hasil = tagihanDariJson(j);

    if (hasil.statusKini == StatusBayar.lunas) {
      revisiData.value++;
    }

    return hasil;
  }

  // -------------------------------------------------------------------------
  // Beranda
  // -------------------------------------------------------------------------

  static Future<RingkasanBeranda> beranda() async {
    final j = await api.get('/beranda');
    final langganan = langgananDariJson(
      j['langganan'] as Map<String, dynamic>,
    );
    return berandaDariJson(j, langganan);
  }

  // -------------------------------------------------------------------------
  // Penjualan
  // -------------------------------------------------------------------------

  static String nomorStrukBerikutnya() {
    // Dipanggil sinkron di UI — akan diambil saat simpanTransaksi.
    return '';
  }

  static Future<String> ambilNomorStrukBerikutnya() async {
    final j = await api.get('/transaksi/nomor-berikutnya');
    return j['nomorStruk'] as String? ?? '';
  }

  static Future<Transaksi> simpanTransaksi({
    required List<ItemKeranjang> item,
    required MetodeBayar metode,
    required StatusTransaksi status,
    String? pelanggan,
    int? uangDiterima,
  }) async {
    final j = await api.post('/transaksi', {
      'item': [
        for (final i in item)
          {
            'produkId': i.produk.id,
            'nama': i.produk.nama,
            'hargaSatuan': i.produk.hargaJual,
            'jumlah': i.jumlah,
          },
      ],
      'metode': switch (metode) {
        MetodeBayar.tunai => 'TUNAI',
        MetodeBayar.qris => 'QRIS',
        MetodeBayar.transfer => 'TRANSFER',
      },
      'status': switch (status) {
        StatusTransaksi.selesai => 'SELESAI',
        StatusTransaksi.ditahan => 'DITAHAN',
        StatusTransaksi.batal => 'BATAL',
      },
      if (pelanggan != null && pelanggan.isNotEmpty) 'pelanggan': pelanggan,
      'uangDiterima': ?uangDiterima,
    });

    revisiData.value++;
    return transaksiDariJson(j);
  }

  static Future<Transaksi> ubahIsiTransaksi(
    Transaksi transaksi, {
    required List<BarisStruk> baris,
  }) async {
    final j = await api.put('/transaksi/${transaksi.id}/isi', {
      'item': [
        for (final b in baris)
          {
            'produkId': b.produkId,
            'nama': b.nama,
            'hargaSatuan': b.hargaSatuan,
            'jumlah': b.jumlah,
          },
      ],
    });

    revisiData.value++;
    return transaksiDariJson(j);
  }

  static Future<Transaksi> lunasiTransaksi(
    Transaksi transaksi, {
    required MetodeBayar metode,
    int? uangDiterima,
  }) async {
    final j = await api.post('/transaksi/${transaksi.id}/lunasi', {
      'metode': switch (metode) {
        MetodeBayar.tunai => 'TUNAI',
        MetodeBayar.qris => 'QRIS',
        MetodeBayar.transfer => 'TRANSFER',
      },
      'uangDiterima': ?uangDiterima,
    });

    revisiData.value++;
    return transaksiDariJson(j);
  }

  static Future<List<Transaksi>> piutang() async {
    final daftar = await api.getDaftar('/transaksi/piutang');
    return daftar
        .map((e) => transaksiDariJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Master data — simpan & hapus
  // -------------------------------------------------------------------------

  static Future<Produk> simpanProduk(Produk produk) async {
    // ID yang dimulai 'p' atau kosong = baru (dari contoh lama), kirim store.
    // ID numerik = dari backend, kirim update.
    final baru = int.tryParse(produk.id) == null;

    final body = <String, dynamic>{
      'nama': produk.nama,
      'kategoriId': produk.kategoriId,
      'hargaJual': produk.hargaJual,
      'satuan': produk.satuan,
      'lacakStok': produk.lacakStok,
      'stok': produk.stok,
    };

    final j = baru
        ? await api.post('/produk', body)
        : await api.patch('/produk/${produk.id}', body);

    revisiData.value++;
    return produkDariJson(j);
  }

  static Future<Kategori> simpanKategori(Kategori kategori) async {
    final baru = int.tryParse(kategori.id) == null;

    final body = <String, dynamic>{
      'nama': kategori.nama,
      'ikon': ikonKeNama(kategori.ikon),
    };

    final j = baru
        ? await api.post('/kategori', body)
        : await api.patch('/kategori/${kategori.id}', body);

    revisiData.value++;
    return kategoriDariJson(j);
  }

  static Future<void> hapusKategori(String id, {String? pindahkanKe}) async {
    final query = pindahkanKe != null ? '?pindahkanKe=$pindahkanKe' : '';
    await api.delete('/kategori/$id$query');
    revisiData.value++;
  }

  static Future<void> urutkanKategori(List<Kategori> urutan) async {
    await api.put('/kategori/urutan', {
      'urutan': [for (final k in urutan) int.tryParse(k.id) ?? k.id],
    });
  }

  static String idKategoriBerikutnya() => 'baru';
  static String idProdukBerikutnya() => 'baru';

  // -------------------------------------------------------------------------
  // Profil & toko
  // -------------------------------------------------------------------------

  static Future<Profil> profil() async {
    final j = await api.get('/auth/saya');
    return profilDariJson(j['profil'] as Map<String, dynamic>);
  }

  static Future<Profil> simpanProfil(Profil profil) async {
    final j = await api.patch('/auth/profil', {
      'nama': profil.nama,
      'email': profil.email,
      'telepon': profil.telepon,
    });
    revisiData.value++;
    return profilDariJson(j);
  }

  static Future<Toko> toko() async {
    final j = await api.get('/toko');
    return tokoDariJson(j);
  }

  static Future<Toko> simpanToko(Toko toko) async {
    final j = await api.put('/toko', {
      'nama_toko': toko.nama,
      'alamat': toko.alamat,
      'telepon': toko.telepon,
    });
    revisiData.value++;
    return tokoDariJson(j);
  }

  static Future<PengaturanStruk> pengaturanStruk() async {
    final j = await api.get('/toko/struk');
    return pengaturanStrukDariJson(j);
  }

  static Future<PengaturanStruk> simpanPengaturanStruk(
    PengaturanStruk pengaturan,
  ) async {
    final j = await api.put('/toko/struk', {
      'kepala': pengaturan.kepala,
      'kaki': pengaturan.kaki,
      'tampilkan_alamat': pengaturan.tampilkanAlamat,
      'tampilkan_telepon': pengaturan.tampilkanTelepon,
      'tampilkan_nama_kasir': pengaturan.tampilkanNamaKasir,
      'lebar': pengaturan.lebar == LebarKertas.mm58 ? 'MM58' : 'MM80',
    });
    revisiData.value++;
    return pengaturanStrukDariJson(j);
  }

  // -------------------------------------------------------------------------
  // Riwayat transaksi
  // -------------------------------------------------------------------------

  static Future<List<Transaksi>> riwayat({
    String cari = '',
    StatusTransaksi? status,
    MetodeBayar? metode,
  }) async {
    final query = <String, String>{};
    if (cari.trim().isNotEmpty) query['cari'] = cari.trim();
    if (status != null) {
      query['status'] = switch (status) {
        StatusTransaksi.selesai => 'SELESAI',
        StatusTransaksi.ditahan => 'DITAHAN',
        StatusTransaksi.batal => 'BATAL',
      };
    }
    if (metode != null) {
      query['metode'] = switch (metode) {
        MetodeBayar.tunai => 'TUNAI',
        MetodeBayar.qris => 'QRIS',
        MetodeBayar.transfer => 'TRANSFER',
      };
    }

    final daftar = await api.getDaftar('/transaksi', query);
    return daftar
        .map((e) => transaksiDariJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Laporan
  // -------------------------------------------------------------------------

  static Future<Laporan> laporan(Periode periode) async {
    final j = await api.get('/laporan', {
      'periode': periodeKeString(periode),
    });
    return laporanDariJson(j);
  }
}
