import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/model.dart';
import 'package:mobile/data/parser.dart';
import 'package:mobile/util/kartu_qris.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Muatan QRIS sepanjang aslinya — string sungguhan dari Mayar berkisar 200-300
/// karakter. Dipakai apa adanya supaya `QrVersions.auto` benar-benar harus
/// menaikkan versi, bukan kebetulan muat di versi terkecil.
const _qris =
    '00020101021226650013CO.XENDIT.WWW0118936000420000000000021500000000000000'
    '003030IDN5204581253033605802ID5920JualinAja Contoh6007Jakarta6105123406'
    '2070703A016304ABCD';

/// Tagihan menunggu yang cukup lengkap untuk digambar.
Tagihan _tagihan({TipeTagihan tipe = TipeTagihan.langganan}) => Tagihan(
  id: 'inv-1',
  nomorInvoice: 'INV/2026/0130',
  tipe: tipe,
  durasi: DurasiPaket.bulanan,
  nominal: 35_000,
  saluran: SaluranBayar.qris,
  status: StatusBayar.menunggu,
  dibuat: DateTime(2026, 9, 14, 20),
  batasBayar: DateTime(2026, 9, 14, 21),
);

/// Hasil pengukuran kode QR di dalam PNG, dihitung dari pikselnya sendiri —
/// bukan dari anggapan tentang cara gambarnya dibuat.
class _UkuranQr {
  const _UkuranQr({
    required this.piksel,
    required this.lebarGambar,
    required this.tinggiGambar,
    required this.modul,
    required this.pxModul,
    required this.kiri,
    required this.atas,
    required this.sunyiKanan,
    required this.sunyiBawah,
    required this.abuTengah,
  });

  /// Piksel gambar, RGBA mentah.
  final Uint8List piksel;
  final int lebarGambar;
  final int tinggiGambar;

  /// Jumlah modul pada sisi kode QR, menurut pustaka QR-nya.
  final int modul;

  /// Sisi satu modul dalam piksel.
  final double pxModul;

  /// Piksel tempat modul (0,0) kode QR dimulai.
  final int kiri;
  final int atas;

  /// Lebar zona sunyi di kanan dan bawah, dalam satuan modul. Yang kiri dan
  /// atas sama dengan [kiri] dan [atas] dibagi [pxModul].
  final double sunyiKanan;
  final double sunyiBawah;

  /// Bagian piksel di dalam kotak QR yang bukan hitam atau putih murni —
  /// yaitu yang jatuh ke anti-alias.
  final double abuTengah;

  double get sunyiKiri => kiri / pxModul;
  double get sunyiAtas => atas / pxModul;

  /// Apakah modul ([baris], [kolom]) tergambar gelap — dibaca dari piksel di
  /// tengah-tengah modul itu, jauh dari tepinya.
  bool modulGelap(int baris, int kolom) {
    final x = kiri + (kolom * pxModul + pxModul / 2).floor();
    final y = atas + (baris * pxModul + pxModul / 2).floor();
    return piksel[(y * lebarGambar + x) * 4] < 128;
  }
}

/// Ukur kode QR dari PNG yang dihasilkan [gambarQris].
///
/// Pindai dilakukan dari berkasnya sendiri supaya tes ini tidak ikut berubah
/// ketika cara menggambarnya diubah — kalau geometrinya salah lagi, angkanya
/// yang berbicara.
Future<_UkuranQr> _ukurQr(Uint8List png) async {
  final kode = await ui.instantiateImageCodec(png);
  final gambar = (await kode.getNextFrame()).image;
  final data = await gambar.toByteData(format: ui.ImageByteFormat.rawRgba);
  final px = data!.buffer.asUint8List();
  final lebar = gambar.width;
  final tinggi = gambar.height;

  bool gelap(int x, int y) => px[(y * lebar + x) * 4] < 128;

  final modul = QrValidator.validate(
    data: _qris,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.L,
  ).qrCode!.moduleCount;

  // Baris tergelap pertama adalah tepi atas kotak QR: di atasnya cuma margin
  // putih. Pita setinggi satu modul di bawahnya sudah cukup untuk menemukan
  // tepi kiri dan kanannya, karena baris teratas tiap mata QR (kotak 7x7 di
  // kiri atas dan kanan atas) pasti menyentuh kedua tepi itu.
  var atas = -1;
  for (var y = 0; y < tinggi && atas < 0; y++) {
    for (var x = 0; x < lebar; x++) {
      if (gelap(x, y)) {
        atas = y;
        break;
      }
    }
  }
  expect(atas, greaterThanOrEqualTo(0), reason: 'gambar tidak punya piksel gelap');

  var kiri = lebar;
  var kanan = -1;
  for (var y = atas; y < tinggi && y < atas + modul; y++) {
    for (var x = 0; x < lebar; x++) {
      if (gelap(x, y)) {
        if (x < kiri) kiri = x;
        if (x > kanan) kanan = x;
      }
    }
  }

  // Baris mana saja yang punya piksel gelap di dalam rentang mendatar kotak QR.
  // Dipakai untuk menemukan tepi bawahnya dan lebar zona sunyi di bawahnya.
  final adaGelap = List<bool>.filled(tinggi, false);
  for (var y = 0; y < tinggi; y++) {
    for (var x = kiri; x <= kanan; x++) {
      if (gelap(x, y)) {
        adaGelap[y] = true;
        break;
      }
    }
  }

  // Tepi bawah: deretan terang pertama yang panjangnya melebihi satu modul.
  // Satu modul penuh yang terang tidak mungkin muncul di tengah kode QR, jadi
  // yang ditemukan pasti zona sunyinya.
  final jaga = modul + 8;
  var bawah = -1;
  for (var y = atas + 1; y + jaga <= tinggi && bawah < 0; y++) {
    var terang = true;
    for (var k = 0; k < jaga && terang; k++) {
      if (adaGelap[y + k]) terang = false;
    }
    if (terang) bawah = y;
  }
  expect(bawah, greaterThan(atas), reason: 'tepi bawah kode QR tidak ditemukan');

  var lebarSunyi = 0;
  for (var y = bawah; y < tinggi && !adaGelap[y]; y++) {
    lebarSunyi++;
  }

  var abu = 0;
  var isi = 0;
  for (var y = atas; y < bawah; y++) {
    for (var x = kiri; x <= kanan; x++) {
      final v = px[(y * lebar + x) * 4];
      isi++;
      if (v > 40 && v < 215) abu++;
    }
  }

  final pxModul = (kanan - kiri + 1) / modul;

  return _UkuranQr(
    piksel: px,
    lebarGambar: lebar,
    tinggiGambar: tinggi,
    modul: modul,
    pxModul: pxModul,
    kiri: kiri,
    atas: atas,
    sunyiKanan: (lebar - 1 - kanan) / pxModul,
    sunyiBawah: lebarSunyi / pxModul,
    abuTengah: isi == 0 ? 1 : abu / isi,
  );
}

void main() {
  group('instruksiDariJson', () {
    test('membaca muatan QRIS mentah dari qrString', () {
      final hasil = instruksiDariJson({'tipe': 'qr_code', 'qrString': _qris});

      expect(hasil, isNotNull);
      expect(hasil!.qrString, _qris);
    });

    test('null saat qrString kosong — layar jatuh ke tautan hosted', () {
      expect(instruksiDariJson({'tipe': 'qr_code', 'qrString': ''}), isNull);
      expect(instruksiDariJson({'tipe': 'qr_code'}), isNull);
    });

    test('bentuk lama berisi qrUrl saja tidak lagi dikenali', () {
      // Baris yang dibuat sebelum kode QR digambar sendiri: instruksi_bayar-nya
      // masih memuat URL pihak ketiga. Harus jadi null supaya layar memakai
      // tautan hosted, bukan kartu QR kosong.
      final hasil = instruksiDariJson({
        'tipe': 'qr_code',
        'qrUrl': 'https://api.qrserver.com/v1/create-qr-code/?data=$_qris',
      });

      expect(hasil, isNull);
    });

    test('tipe yang bukan String ditolak', () {
      expect(instruksiDariJson({'tipe': 7, 'qrString': _qris}), isNull);
    });

    test('tipe yang tidak dikenal ditolak', () {
      expect(instruksiDariJson({'tipe': 'va', 'kodeBayar': '123'}), isNull);
    });
  });

  group('gambarQris', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    test('menghasilkan PNG yang bisa dikenali', () async {
      final bytes = await gambarQris(_tagihan(), _qris);

      // Delapan byte pertama berkas PNG. Kalau `toByteData` suatu saat diminta
      // format lain, penegasan ini yang menangkapnya.
      expect(
        bytes.sublist(0, 8),
        equals(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      );
      expect(bytes.length, greaterThan(1000));
    });

    test('bekerja untuk tagihan Pustaka yang tanpa berlakuSampai', () async {
      // Tagihan Pustaka tidak punya `berlakuSampai`; gambar tetap harus jadi
      // karena yang dipakai cuma `batasBayar`.
      final bytes = await gambarQris(
        _tagihan(tipe: TipeTagihan.pustakaSatuan),
        _qris,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));
    });

    test('setiap gambar punya lebar yang sama, apa pun panjang isinya', () async {
      // Lebar ada di byte 16-19 (big-endian) pada header IHDR.
      int lebar(Uint8List b) =>
          (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];

      final pendek = await gambarQris(_tagihan(), 'pendek');
      final panjang = await gambarQris(_tagihan(), _qris);

      expect(lebar(pendek), 1000);
      expect(lebar(panjang), 1000);
    });

    test('zona sunyi sekeliling kode QR cukup lebar untuk dipindai', () async {
      // Inilah kerusakannya. Spesifikasi QR (ISO/IEC 18004) meminta zona sunyi
      // minimal 4 modul; di bawah itu pemindai kehilangan batas simbolnya.
      // QR di layar punya zona yang lega karena duduk di dalam kartu berpadding,
      // jadi versi di layar terbaca sementara gambar hasil unduhan tidak.
      final u = await _ukurQr(await gambarQris(_tagihan(), _qris));

      expect(u.sunyiKiri, greaterThanOrEqualTo(4), reason: 'kiri');
      expect(u.sunyiKanan, greaterThanOrEqualTo(4), reason: 'kanan');
      expect(u.sunyiAtas, greaterThanOrEqualTo(4), reason: 'atas');
      expect(u.sunyiBawah, greaterThanOrEqualTo(4), reason: 'bawah');
    });

    test('sisi kode QR kelipatan bulat jumlah modulnya', () async {
      // Kalau tidak bulat, tiap tepi modul jatuh di tengah piksel dan pemindai
      // harus menebak ambang hitam-putihnya.
      final u = await _ukurQr(await gambarQris(_tagihan(), _qris));

      expect(u.pxModul, equals(u.pxModul.roundToDouble()), reason: 'px/modul');
      expect(u.pxModul, greaterThanOrEqualTo(4), reason: 'px/modul terlalu kecil');
    });

    test('tidak ada piksel abu-abu di dalam kode QR', () async {
      final u = await _ukurQr(await gambarQris(_tagihan(), _qris));

      expect(u.abuTengah, lessThan(0.005), reason: 'anti-alias sistemik');
    });

    test('pikselnya membentuk kode QR yang sama persis dengan muatannya', () async {
      // Pemeriksaan yang paling menentukan: tiap modul dibaca kembali dari
      // piksel di tengahnya lalu dibandingkan dengan modul yang seharusnya.
      // Satu modul bergeser saja sudah merusak muatannya, dan itu ketahuan di
      // sini tanpa perlu aplikasi pemindai sungguhan.
      final u = await _ukurQr(await gambarQris(_tagihan(), _qris));

      final qr = QrValidator.validate(
        data: _qris,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      ).qrCode!;
      final acuan = QrImage(qr);

      expect(acuan.moduleCount, u.modul);

      final beda = <String>[];
      for (var baris = 0; baris < u.modul; baris++) {
        for (var kolom = 0; kolom < u.modul; kolom++) {
          if (u.modulGelap(baris, kolom) != acuan.isDark(baris, kolom)) {
            beda.add('($baris,$kolom)');
          }
        }
      }

      expect(beda, isEmpty, reason: '${beda.length} modul tidak cocok');
    });
  });
}
