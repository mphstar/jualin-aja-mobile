import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/data/contoh.dart';
import 'package:mobile/data/model.dart';
import 'package:mobile/data/repositori.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/kasir_screen.dart';
import 'package:mobile/theme/tokens.dart';
import 'package:mobile/util/format.dart';
import 'package:mobile/widgets/batang.dart';
import 'package:mobile/widgets/peraga.dart';
import 'package:mobile/widgets/rangka.dart';

/// Pengganti `pumpAndSettle`.
///
/// `pumpAndSettle` TIDAK BISA dipakai di aplikasi ini: rangka pemuatan
/// berdenyut memakai `AnimationController.repeat()`, dan animasi yang tidak
/// pernah berhenti membuat `pumpAndSettle` berputar sampai kehabisan waktu.
/// Memajukan jam secara bertahap menyelesaikan `Future` repositori sekaligus
/// transisi rute, tanpa pernah menunggu animasi berhenti.
Future<void> tenang(WidgetTester tester, {int langkah = 8}) async {
  for (var i = 0; i < langkah; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> ketuk(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tenang(tester);
}

/// Menempuh SELURUH alur pembuka sampai Beranda: sambutan → jenis usaha →
/// keluhan → masuk. Bukan jalan pintas — kalau salah satu tombol lanjut tidak
/// pernah aktif, tes ini yang gagal lebih dulu, bukan pengguna.
Future<void> masuk(WidgetTester tester) async {
  await tester.pumpWidget(const AplikasiPos());
  await tenang(tester);

  await ketuk(tester, find.widgetWithText(FilledButton, 'Mulai'));
  await ketuk(tester, find.text('Kafe'));
  await ketuk(tester, find.widgetWithText(FilledButton, 'Lanjut'));
  await ketuk(tester, find.text('Stok sering tidak cocok'));
  await ketuk(tester, find.widgetWithText(FilledButton, 'Selesai'));
  await ketuk(tester, find.widgetWithText(FilledButton, 'Masuk'));
}

/// Mengetuk tujuan navigasi lewat bilah bawah — bukan lewat `find.text` polos,
/// yang juga akan mengenai judul halaman bernama sama ("Laporan", "Produk").
Future<void> keTab(WidgetTester tester, String label) async {
  await ketuk(
    tester,
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
}

void ukuran(WidgetTester tester, double lebar, [double tinggi = 900]) {
  tester.view.physicalSize = Size(lebar, tinggi);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  tearDown(() {
    // Keduanya global. Sakelar peragaan mengubah lapisan data, dan pembayaran
    // demo benar-benar memperpanjang langganan — tanpa pengembalian ini, tes
    // berikutnya mewarisi langganan yang sudah dibayar tes sebelumnya, dan
    // kegagalannya akan tergantung pada urutan tes.
    modeUji.value = ModeUji.normal;
    aturUlangContoh();
  });

  // -------------------------------------------------------------------------
  // Alur
  // -------------------------------------------------------------------------

  testWidgets('aplikasi terbuka di sambutan, bukan di masuk atau kasir', (
    tester,
  ) async {
    ukuran(tester, 400);
    await tester.pumpWidget(const AplikasiPos());
    await tenang(tester);

    expect(find.widgetWithText(FilledButton, 'Mulai'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('alur pembuka tidak pernah memamerkan penanda foto kosong', (
    tester,
  ) async {
    // Penjaga regresi untuk bug yang sungguhan pernah tayang: layar PERTAMA
    // aplikasi menampilkan lingkaran abu bertuliskan "Foto belum ada".
    // Penanda itu benar di layar Produk — di sana ia memang menunggu unggahan
    // pemilik toko — tapi di layar pembuka ia mengumumkan bahwa produknya
    // belum jadi.
    ukuran(tester, 400);
    await tester.pumpWidget(const AplikasiPos());
    await tenang(tester);

    // Ketiga slide: struk, kartu stok, panel laporan.
    expect(find.byType(PeragaStruk), findsOneWidget);
    expect(find.text('Foto belum ada'), findsNothing);

    for (final peraga in [PeragaStok, PeragaLaporan]) {
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tenang(tester);
      expect(find.byType(peraga), findsOneWidget);
      expect(find.text('Foto belum ada'), findsNothing);
    }

    // Sampai layar masuk pun tidak ada.
    await ketuk(tester, find.widgetWithText(TextButton, 'Masuk'));
    expect(find.text('Foto belum ada'), findsNothing);
    expect(find.byType(TandaMerek), findsWidgets);
  });

  testWidgets('layar pertanyaan memberi tahu masih ada berapa langkah lagi', (
    tester,
  ) async {
    ukuran(tester, 400);
    await tester.pumpWidget(const AplikasiPos());
    await tenang(tester);

    await ketuk(tester, find.widgetWithText(FilledButton, 'Mulai'));
    expect(find.text('1/2'), findsOneWidget);

    await ketuk(tester, find.text('Kafe'));
    await ketuk(tester, find.widgetWithText(FilledButton, 'Lanjut'));
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('"Sudah punya akun" melewati pertanyaan, langsung ke masuk', (
    tester,
  ) async {
    ukuran(tester, 400);
    await tester.pumpWidget(const AplikasiPos());
    await tenang(tester);
    await ketuk(tester, find.widgetWithText(TextButton, 'Masuk'));

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Toko Anda\njenisnya apa?'), findsNothing);
  });

  testWidgets('tombol lanjut mati sampai pertanyaan dijawab', (tester) async {
    ukuran(tester, 400);
    await tester.pumpWidget(const AplikasiPos());
    await tenang(tester);
    await ketuk(tester, find.widgetWithText(FilledButton, 'Mulai'));

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Lanjut'))
          .onPressed,
      isNull,
    );

    await ketuk(tester, find.text('Kafe'));

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Lanjut'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('setelah masuk mendarat di Beranda, bukan Kasir', (tester) async {
    ukuran(tester, 400);
    await masuk(tester);

    expect(find.text('Penjualan hari ini'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Buka kasir'), findsOneWidget);
    expect(find.byType(KasirScreen), findsNothing);
  });

  testWidgets('kasir dibuka dari Beranda sebagai layar penuh', (tester) async {
    ukuran(tester, 400);
    await masuk(tester);
    await ketuk(tester, find.widgetWithText(FilledButton, 'Buka kasir'));

    expect(find.byType(KasirScreen), findsOneWidget);
    // Kasir bukan tujuan navigasi — bilah nav tidak boleh ikut terbawa.
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('header kasir: keranjang mati saat kosong, hidup saat ada isi', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);
    await ketuk(tester, find.widgetWithText(FilledButton, 'Buka kasir'));

    // Keranjang selalu ada di tempat yang sama, tapi mati selama kosong —
    // tombol yang hilang-muncul tidak pernah sempat dipelajari letaknya.
    final keranjang = find.widgetWithIcon(
      IconButton,
      Icons.shopping_bag_outlined,
    );
    expect(keranjang, findsOneWidget);
    expect(tester.widget<IconButton>(keranjang).onPressed, isNull);
    expect(find.text('Kosongkan'), findsNothing);

    await ketuk(tester, find.byIcon(Icons.add).first);
    expect(tester.widget<IconButton>(keranjang).onPressed, isNotNull);
    expect(find.text('Kosongkan'), findsOneWidget);

    // Lencana membawa jumlahnya.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );

    // Dan tombol keranjang benar-benar membuka keranjangnya.
    await ketuk(tester, keranjang);
    expect(find.text('Keranjang'), findsOneWidget);
  });

  testWidgets('Kosongkan minta konfirmasi, dan Batal tidak menghapus apa pun', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);
    await ketuk(tester, find.widgetWithText(FilledButton, 'Buka kasir'));
    await ketuk(tester, find.byIcon(Icons.add).first);

    await ketuk(tester, find.text('Kosongkan'));
    expect(find.text('Kosongkan keranjang?'), findsOneWidget);

    await ketuk(tester, find.text('Batal'));
    expect(find.byType(BilahKeranjang), findsOneWidget, reason: 'isi terhapus');
  });

  testWidgets('panel Beranda membawa pembanding, bukan cuma satu angka', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);

    // Tujuh batang percikan — angka tunggal tanpa pembanding tidak bisa
    // dinilai bagus atau tidak.
    expect(find.byType(Percikan), findsOneWidget);
    expect(find.text('Tujuh hari terakhir'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Navigasi
  // -------------------------------------------------------------------------

  testWidgets('lebar ponsel memakai bilah bawah, tablet memakai rail', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    tester.view.physicalSize = const Size(800, 900);
    await tenang(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Riwayat hidup sebagai tab di dalam Laporan, bukan tujuan nav', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);

    // Lima tujuan, dan "Riwayat" bukan salah satunya.
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Riwayat'),
      ),
      findsNothing,
    );

    await keTab(tester, 'Laporan');
    expect(find.widgetWithText(Tab, 'Ringkasan'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Riwayat'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Empat keadaan (PRD §8)
  // -------------------------------------------------------------------------

  testWidgets('keadaan MEMUAT menampilkan rangka, bukan layar kosong', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);

    modeUji.value = ModeUji.memuat;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Rangka), findsWidgets);
    expect(find.text('Penjualan hari ini'), findsNothing);

    // Keadaan "memuat" ditahan sepuluh detik; timernya harus benar-benar
    // habis sebelum tes berakhir, atau kerangka tes melaporkan timer
    // menggantung.
    modeUji.value = ModeUji.normal;
    await tenang(tester, langkah: 30);
  });

  testWidgets('keadaan KOSONG menjelaskan keadaannya, bukan diam', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);

    modeUji.value = ModeUji.kosong;
    await tenang(tester);
    expect(find.text('Belum ada penjualan'), findsOneWidget);

    await keTab(tester, 'Produk');
    expect(find.text('Belum ada produk'), findsOneWidget);
  });

  testWidgets('keadaan GALAT bisa dicoba lagi dan benar-benar pulih', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);

    modeUji.value = ModeUji.galat;
    await tenang(tester);
    expect(find.text('Gagal memuat'), findsOneWidget);

    // Pulihkan sambungannya, lalu tekan tombolnya — bukan cuma memeriksa
    // tombolnya ada.
    modeUji.value = ModeUji.normal;
    await tenang(tester);
    expect(find.text('Penjualan hari ini'), findsOneWidget);
  });

  testWidgets('kasir menolak berjalan tanpa produk, dan bilang kenapa', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);
    modeUji.value = ModeUji.kosong;
    await tenang(tester);

    await ketuk(tester, find.widgetWithText(FilledButton, 'Buka kasir'));
    expect(find.text('Belum ada produk'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Laporan
  // -------------------------------------------------------------------------

  testWidgets('Laporan menampilkan angka turunan, bukan tempat kosong', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);
    await keTab(tester, 'Laporan');

    expect(find.text('Omzet 7 hari'), findsOneWidget);
    expect(find.text('Produk terlaris'.toUpperCase()), findsOneWidget);
    expect(find.text('Metode pembayaran'.toUpperCase()), findsOneWidget);

    // Ganti periode → judul panel ikut berganti.
    await ketuk(tester, find.text('30 hari'));
    expect(find.text('Omzet 30 hari'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Lantai lebar — tiap layar, tiap lebar
  // -------------------------------------------------------------------------

  for (final lebar in [320.0, 375.0, 414.0, 768.0]) {
    testWidgets('tidak ada luapan pada lebar ${lebar.toInt()} px', (
      tester,
    ) async {
      ukuran(tester, lebar);
      await masuk(tester);
      expect(tester.takeException(), isNull);

      final pakaiBilah = lebar < Ambang.ringkas;
      for (final tujuan in ['Produk', 'Laporan', 'Resep', 'Akun', 'Beranda']) {
        if (pakaiBilah) {
          await keTab(tester, tujuan);
        } else {
          await ketuk(
            tester,
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.text(tujuan),
            ),
          );
        }
        expect(tester.takeException(), isNull, reason: 'luapan di $tujuan');
      }

      // Alur pembayaran — dua layar dengan angka panjang dan nomor VA 19
      // karakter, keduanya kandidat kuat untuk meluber di layar sempit.
      if (pakaiBilah) {
        await keTab(tester, 'Akun');
        await ketuk(tester, find.text('Perpanjang langganan'));
        expect(tester.takeException(), isNull, reason: 'luapan di Perpanjang');

        await ketuk(tester, find.text('Virtual Account BCA'));
        await ketuk(
          tester,
          find.widgetWithText(FilledButton, 'Bayar sekarang'),
        );
        expect(tester.takeException(), isNull, reason: 'luapan di Status');

        await ketuk(
          tester,
          find.widgetWithText(FilledButton, 'Saya sudah bayar'),
        );
        expect(tester.takeException(), isNull, reason: 'luapan di Lunas');

        await ketuk(tester, find.widgetWithText(FilledButton, 'Selesai'));
        await keTab(tester, 'Beranda');
      }

      // Kasir — layar terpadat di aplikasi.
      await ketuk(tester, find.widgetWithText(FilledButton, 'Buka kasir'));
      expect(tester.takeException(), isNull, reason: 'luapan di Kasir');

      // Dan kasir DENGAN keranjang terisi: bilah keranjang mengambang baru
      // muncul setelah ada isi, jadi tanpa langkah ini ia tidak pernah diuji
      // pada lebar tersempit.
      await ketuk(tester, find.byIcon(Icons.add).first);
      expect(tester.takeException(), isNull, reason: 'luapan di keranjang');
      expect(
        find.byType(BilahKeranjang),
        pakaiBilah ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('alur pembuka muat di layar pendek 320x568', (tester) async {
    // Ponsel lama masih banyak dipakai pemilik warung. Slide sambutan punya
    // potret 150 px plus judul tiga baris — tanpa gulir ia pasti meluber di
    // tinggi segini, dan tes ini yang memastikan gulirnya benar-benar ada.
    ukuran(tester, 320, 568);
    await masuk(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Penjualan hari ini'), findsOneWidget);
  });

  testWidgets('mode gelap berjalan di seluruh tujuan', (tester) async {
    // Palet gelap BUKAN pembalikan otomatis dari palet terang — beberapa
    // hubungan sengaja dibalik (permukaan fokus jadi lebih terang, tombol
    // utama jadi terang-di-atas-gelap). Yang disusun tangan harus diuji.
    ukuran(tester, 400);
    await masuk(tester);
    await keTab(tester, 'Akun');
    await ketuk(tester, find.text('Tampilan'));
    expect(tester.takeException(), isNull);

    for (final tujuan in ['Beranda', 'Produk', 'Laporan', 'Resep', 'Akun']) {
      await keTab(tester, tujuan);
      expect(tester.takeException(), isNull, reason: 'mode gelap di $tujuan');
    }
    expect(find.text('Mode gelap'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Pembayaran langganan
  // -------------------------------------------------------------------------

  /// Akun → Perpanjang langganan.
  Future<void> keLayarBayar(WidgetTester tester) async {
    await masuk(tester);
    await keTab(tester, 'Akun');
    await ketuk(tester, find.text('Perpanjang langganan'));
  }

  testWidgets('layar perpanjang menolak lanjut sebelum metode dipilih', (
    tester,
  ) async {
    ukuran(tester, 400);
    await keLayarBayar(tester);

    // Durasi punya bawaan, metode tidak — jadi tombolnya mati dengan label
    // yang menyebut apa yang kurang, bukan "Bayar sekarang" yang lalu menolak.
    expect(find.text('Pilih metode pembayaran'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Pilih metode pembayaran'),
          )
          .onPressed,
      isNull,
    );

    await ketuk(tester, find.text('QRIS'));
    expect(find.widgetWithText(FilledButton, 'Bayar sekarang'), findsOneWidget);
  });

  testWidgets('hemat dihitung dari harga, bukan angka pemasaran', (
    tester,
  ) async {
    ukuran(tester, 400);
    await keLayarBayar(tester);

    // 6 × 99.000 = 594.000 vs 499.000 → 16%
    // 12 × 99.000 = 1.188.000 vs 899.000 → 24%
    expect(find.text('Hemat 16%'), findsOneWidget);
    expect(find.text('Hemat 24%'), findsOneWidget);
    // Paket bulanan tidak punya pembanding, jadi tidak berpil.
    expect(find.textContaining('Hemat'), findsNWidgets(2));
  });

  testWidgets('sisa hari tidak hangus, dan itu dikatakan di layar', (
    tester,
  ) async {
    ukuran(tester, 400);
    await keLayarBayar(tester);

    // Kartu rincian ada di bawah daftar metode, jadi harus digulir dulu.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tenang(tester);

    // PRD §4.4 — perpanjangan menyambung dari tanggal berakhir, bukan dari
    // hari ini. Kalimatnya wajib ada; tanpa itu orang menunda sampai mati.
    expect(find.textContaining('tidak hangus'), findsOneWidget);

    final akhirBaru = langgananContoh.berakhirSetelahPerpanjang(
      DurasiPaket.semesteran,
    );
    expect(find.text(tanggal(akhirBaru)), findsWidgets);
  });

  testWidgets('alur bayar sampai lunas benar-benar memperpanjang langganan', (
    tester,
  ) async {
    ukuran(tester, 400);
    final sebelum = langgananContoh.tanggalBerakhir;

    await keLayarBayar(tester);
    await ketuk(tester, find.text('Virtual Account BCA'));
    await ketuk(tester, find.widgetWithText(FilledButton, 'Bayar sekarang'));

    // Keadaan menunggu: nomor VA dan cara membayarnya harus ada.
    expect(find.text('Menunggu pembayaran'), findsOneWidget);
    expect(find.text('8808 0812 3456 7890'), findsOneWidget);
    expect(find.text('Cara membayar'.toUpperCase()), findsOneWidget);

    await ketuk(tester, find.widgetWithText(FilledButton, 'Saya sudah bayar'));
    expect(find.text('Lunas'), findsWidgets);

    // Yang diuji bukan gerbang pembayarannya, tapi apakah dunia ikut berubah.
    expect(langgananContoh.tanggalBerakhir.isAfter(sebelum), isTrue);
    expect(tagihanContoh.first.status, StatusBayar.lunas);

    await ketuk(tester, find.widgetWithText(FilledButton, 'Selesai'));
    // Kembali ke Akun, dan sisa harinya sudah bertambah.
    expect(find.text('Perpanjang langganan'), findsOneWidget);
    expect(find.text(sisaHari(langgananContoh.sisaHari)), findsOneWidget);
  });

  testWidgets('"Saya sudah bayar" sebelum dana masuk mengatakan apa adanya', (
    tester,
  ) async {
    ukuran(tester, 400);
    await keLayarBayar(tester);
    await ketuk(tester, find.text('QRIS'));
    await ketuk(tester, find.widgetWithText(FilledButton, 'Bayar sekarang'));

    // Mode kosong menirukan keadaan paling sering: pengguna menekan tombol
    // sebelum dananya benar-benar masuk.
    modeUji.value = ModeUji.kosong;
    await ketuk(tester, find.widgetWithText(FilledButton, 'Saya sudah bayar'));

    expect(find.textContaining('belum terdeteksi'), findsOneWidget);
    expect(find.text('Menunggu pembayaran'), findsOneWidget);
  });

  testWidgets('riwayat pembayaran memuat tagihan lama dan statusnya', (
    tester,
  ) async {
    ukuran(tester, 400);
    await masuk(tester);
    await keTab(tester, 'Akun');
    await ketuk(tester, find.text('Riwayat pembayaran'));

    expect(find.text('INV/2026/0031'), findsOneWidget);
    expect(find.text('Kedaluwarsa'), findsOneWidget);
    expect(find.text('Lunas'), findsNWidgets(2));
  });

  // -------------------------------------------------------------------------
  // Aturan domain — disalin dari PRD, jadi wajib diuji terpisah dari tampilan
  // -------------------------------------------------------------------------

  group('status langganan (PRD §4.2)', () {
    Langganan buat({
      required int sisa,
      bool tangguh = false,
      DurasiPaket d = DurasiPaket.bulanan,
    }) => Langganan(
      durasi: d,
      tanggalMulai: DateTime.now().subtract(const Duration(days: 30)),
      tanggalBerakhir: DateTime.now().add(Duration(days: sisa)),
      ditangguhkan: tangguh,
    );

    test('ditangguhkan menang atas segalanya', () {
      expect(buat(sisa: 300, tangguh: true).status, StatusLangganan.nonaktif);
    });

    test('lewat tanggal berarti kedaluwarsa', () {
      expect(buat(sisa: -1).status, StatusLangganan.kedaluwarsa);
    });

    test('tujuh hari atau kurang berarti akan berakhir', () {
      expect(buat(sisa: 7).status, StatusLangganan.akanBerakhir);
      expect(buat(sisa: 8).status, StatusLangganan.aktif);
    });

    test('uji coba yang masih panjang tetap terbaca uji coba', () {
      expect(
        buat(sisa: 10, d: DurasiPaket.ujiCoba).status,
        StatusLangganan.ujiCoba,
      );
    });

    test('resep terkunci hanya saat kedaluwarsa atau nonaktif (PRD §4.3)', () {
      expect(buat(sisa: 3).bolehUnduhResep, isTrue);
      expect(buat(sisa: -1).bolehUnduhResep, isFalse);
      expect(buat(sisa: 300, tangguh: true).bolehUnduhResep, isFalse);
    });
  });

  test('total struk diturunkan dari barisnya, bukan disimpan', () {
    final t = Transaksi(
      id: 'x',
      nomorStruk: 'STR/2026/0001',
      waktu: DateTime.now(),
      metode: MetodeBayar.tunai,
      status: StatusTransaksi.selesai,
      baris: const [
        BarisStruk(
          produkId: 'p1',
          nama: 'Kopi Susu',
          hargaSatuan: 18000,
          jumlah: 2,
        ),
        BarisStruk(
          produkId: 'p2',
          nama: 'Teh Tarik',
          hargaSatuan: 14000,
          jumlah: 1,
        ),
      ],
    );
    expect(t.total, 50000);
    expect(t.jumlahItem, 3);
  });

  test('data contoh deterministik dan tidak pernah bertanggal masa depan', () {
    final kini = DateTime.now();
    expect(transaksiContoh, isNotEmpty);
    expect(
      transaksiContoh.every((t) => !t.waktu.isAfter(kini)),
      isTrue,
      reason: 'ada transaksi bertanggal masa depan',
    );
    // Terbaru di depan.
    for (var i = 1; i < transaksiContoh.length; i++) {
      expect(
        transaksiContoh[i].waktu.isAfter(transaksiContoh[i - 1].waktu),
        isFalse,
      );
    }
  });

  test('laporan tidak membagi dengan nol saat belum ada transaksi', () {
    const kosong = Laporan(
      periode: Periode.hariIni,
      omzet: 0,
      transaksi: 0,
      item: 0,
      harian: [],
      terlaris: [],
      metode: [],
    );
    expect(kosong.rataPerStruk, 0);
    expect(kosong.kosong, isTrue);
  });

  test('ambang tata letak berurutan', () {
    expect(Ambang.ringkas, lessThan(Ambang.luas));
  });
}
