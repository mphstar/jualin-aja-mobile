import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ilustrasi garis untuk alur pembuka dan layar masuk.
///
/// Kenapa digambar, bukan diunggah sebagai aset. Tiga alasan yang semuanya
/// praktis: gambarnya ikut mode terang/gelap tanpa perlu dua berkas, tajam di
/// kerapatan layar mana pun tanpa varian @2x/@3x, dan tidak menambah satu pun
/// dependensi atau berkas aset ke proyek.
///
/// Kenapa monokrom. `design.md` mengunci satu aturan: aksi adalah tinta, dan
/// kroma HANYA milik empat status. Ilustrasi berwarna akan menjadi satu-satunya
/// tempat warna muncul tanpa berarti apa-apa — dan begitu itu terjadi, warna
/// status kehilangan daya bicaranya di seluruh aplikasi.
///
/// Semua koordinat ditulis dalam ruang desain 200×150, lalu diskalakan ke
/// ukuran sesungguhnya. Menulis pecahan lebar (`size.width * 0.37`) membuat
/// gambar mustahil disunting; angka desain bisa dibaca seperti gambar teknik.
const double _lebarDesain = 200;
const double _tinggiDesain = 150;

/// Bobot garis dalam satuan desain. Dua tingkat saja — struktur dan rincian.
const double _garisTebal = 2.4;
const double _garisTipis = 1.4;

/// Bingkai bersama semua ilustrasi.
///
/// Rasionya dikunci supaya carousel tidak melompat saat digeser: ketiga slide
/// memakai kotak yang persis sama, apa pun isinya.
class Ilustrasi extends StatelessWidget {
  const Ilustrasi({super.key, required this.gambar, this.lebarMaks = 268});

  final GambarIlustrasi gambar;
  final double lebarMaks;

  @override
  Widget build(BuildContext context) {
    final palet = _Palet(
      tinta: context.warna.onSurface,
      redup: context.warna.onSurfaceVariant,
      isian: context.aksen.isian,
      kertas: context.warna.surfaceContainerLowest,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: lebarMaks),
        child: AspectRatio(
          aspectRatio: _lebarDesain / _tinggiDesain,
          // Dekoratif: pembaca layar tidak perlu mendengar apa pun soal ini,
          // teks di bawahnya yang membawa maknanya.
          child: ExcludeSemantics(
            child: CustomPaint(painter: _PelukisIlustrasi(gambar, palet)),
          ),
        ),
      ),
    );
  }
}

/// Empat gambar yang tersedia.
enum GambarIlustrasi {
  /// Etalase warung. "Masuk ke toko Anda" — dan yang digambar memang tokonya.
  etalase,

  /// Ponsel dengan busur jangkauan jempol — "muat di satu tangan".
  kasir,

  /// Rak dengan satu slot kosong — "stok ikut turun sendiri".
  rak,

  /// Panel laporan dan buku resep — "laporan dan resep ikut sekalian".
  laporan,
}

@immutable
class _Palet {
  const _Palet({
    required this.tinta,
    required this.redup,
    required this.isian,
    required this.kertas,
  });

  final Color tinta;
  final Color redup;
  final Color isian;
  final Color kertas;
}

class _PelukisIlustrasi extends CustomPainter {
  _PelukisIlustrasi(this.gambar, this.palet);

  final GambarIlustrasi gambar;
  final _Palet palet;

  @override
  void paint(Canvas kanvas, Size ukuran) {
    kanvas.save();
    kanvas.scale(ukuran.width / _lebarDesain);

    final juru = _Juru(kanvas, palet);
    switch (gambar) {
      case GambarIlustrasi.etalase:
        _etalase(juru);
      case GambarIlustrasi.kasir:
        _kasir(juru);
      case GambarIlustrasi.rak:
        _rak(juru);
      case GambarIlustrasi.laporan:
        _laporan(juru);
    }

    kanvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PelukisIlustrasi lama) =>
      lama.gambar != gambar ||
      lama.palet.tinta != palet.tinta ||
      lama.palet.redup != palet.redup ||
      lama.palet.isian != palet.isian ||
      lama.palet.kertas != palet.kertas;
}

// ---------------------------------------------------------------------------
// Juru gambar — kuas dan bentuk dasar
// ---------------------------------------------------------------------------

/// Pembungkus tipis di atas [Canvas].
///
/// Ada supaya keempat gambar memakai bobot garis, ujung, dan sambungan yang
/// sama persis. Menyetel `Paint` di tiap pemanggilan adalah cara paling cepat
/// membuat satu gambar diam-diam bergaris lebih tebal dari yang lain.
class _Juru {
  _Juru(this.kanvas, this.palet);

  final Canvas kanvas;
  final _Palet palet;

  Paint _kuas(Color warna, double tebal) => Paint()
    ..color = warna
    ..style = PaintingStyle.stroke
    ..strokeWidth = tebal
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Paint _isi(Color warna) => Paint()
    ..color = warna
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  void garis(Offset a, Offset b, {bool tipis = false, Color? warna}) {
    kanvas.drawLine(
      a,
      b,
      _kuas(warna ?? palet.tinta, tipis ? _garisTipis : _garisTebal),
    );
  }

  void jalur(Path p, {bool tipis = false, Color? warna}) {
    kanvas.drawPath(
      p,
      _kuas(warna ?? palet.tinta, tipis ? _garisTipis : _garisTebal),
    );
  }

  void jalurIsi(Path p, Color warna) => kanvas.drawPath(p, _isi(warna));

  void kotak(Rect r, double lengkung, {bool tipis = false, Color? warna}) {
    kanvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(lengkung)),
      _kuas(warna ?? palet.tinta, tipis ? _garisTipis : _garisTebal),
    );
  }

  void kotakIsi(Rect r, double lengkung, Color warna) {
    kanvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(lengkung)),
      _isi(warna),
    );
  }

  void bulat(Offset pusat, double jari, {bool tipis = false, Color? warna}) {
    kanvas.drawCircle(
      pusat,
      jari,
      _kuas(warna ?? palet.tinta, tipis ? _garisTipis : _garisTebal),
    );
  }

  void bulatIsi(Offset pusat, double jari, Color warna) =>
      kanvas.drawCircle(pusat, jari, _isi(warna));

  /// Garis putus-putus lurus. Dipakai untuk hal yang BELUM ada — slot rak yang
  /// kosong — supaya bedanya dengan barang yang ada terbaca tanpa satu kata pun.
  void garisPutus(
    Offset a,
    Offset b, {
    double panjang = 4,
    double jeda = 3.4,
    Color? warna,
  }) {
    final total = (b - a).distance;
    if (total == 0) return;
    final arah = (b - a) / total;
    final kuas = _kuas(warna ?? palet.redup, _garisTipis);

    var t = 0.0;
    while (t < total) {
      final akhir = math.min(t + panjang, total);
      kanvas.drawLine(a + arah * t, a + arah * akhir, kuas);
      t = akhir + jeda;
    }
  }

  /// Busur putus-putus, untuk jangkauan jempol.
  void busurPutus(Rect kotak, double mulai, double sapu, {Color? warna}) {
    const langkah = 0.14;
    const jeda = 0.09;
    final kuas = _kuas(warna ?? palet.redup, _garisTipis);

    var sudut = mulai;
    while (sudut < mulai + sapu) {
      final panjang = math.min(langkah, mulai + sapu - sudut);
      kanvas.drawArc(kotak, sudut, panjang, false, kuas);
      sudut += langkah + jeda;
    }
  }
}

// ---------------------------------------------------------------------------
// 1 · Etalase warung
// ---------------------------------------------------------------------------

void _etalase(_Juru j) {
  const dasar = 138.0;

  // Tanah. Digambar lebih dulu supaya bangunan berdiri DI ATASNYA, bukan
  // melayang — satu garis ini yang membuat seluruh gambar punya bobot.
  j.garis(
    const Offset(16, dasar),
    const Offset(184, dasar),
    warna: j.palet.redup,
  );

  // Badan bangunan.
  j.kotak(const Rect.fromLTRB(34, 58, 166, dasar), 3);

  // Tenda bergelombang. Lengkung di tepi bawahnya yang membuat benda ini
  // langsung terbaca sebagai warung dan bukan sebagai kotak biasa.
  const kiri = 26.0, kanan = 174.0, atasTenda = 42.0, bawahTenda = 60.0;
  const jumlahGelombang = 8;
  const lebarGelombang = (kanan - kiri) / jumlahGelombang;

  final tenda = Path()
    ..moveTo(kiri, bawahTenda)
    ..lineTo(kiri, atasTenda)
    ..lineTo(kanan, atasTenda)
    ..lineTo(kanan, bawahTenda);
  for (var i = jumlahGelombang; i > 0; i--) {
    final x = kiri + lebarGelombang * (i - 1);
    tenda.arcToPoint(
      Offset(x, bawahTenda),
      radius: const Radius.circular(lebarGelombang / 2),
      clockwise: false,
    );
  }
  j.jalur(tenda);

  // Garis-garis tenda — hanya sampai pangkal gelombang, supaya tidak menabrak
  // lengkungnya.
  for (var i = 1; i < jumlahGelombang; i++) {
    final x = kiri + lebarGelombang * i;
    j.garis(
      Offset(x, atasTenda + 2),
      Offset(x, bawahTenda - 1),
      tipis: true,
      warna: j.palet.redup,
    );
  }

  // Papan nama: satu-satunya bidang tinta pejal di gambar ini. Ia jadi titik
  // berat yang menahan mata, peran yang di layar sungguhan dipegang tombol
  // utama — bentuk yang sama, bahasa yang sama.
  j.kotakIsi(const Rect.fromLTRB(70, 14, 130, 36), 6, j.palet.tinta);
  j.garis(const Offset(100, 36), const Offset(100, 42), tipis: true);
  // Dua goresan wordmark di atas papan.
  j.garis(
    const Offset(80, 22),
    const Offset(120, 22),
    tipis: true,
    warna: j.palet.kertas,
  );
  j.garis(
    const Offset(80, 29),
    const Offset(106, 29),
    tipis: true,
    warna: j.palet.kertas,
  );

  // Pintu.
  j.kotak(const Rect.fromLTRB(44, 88, 74, dasar), 3, tipis: true);
  j.bulatIsi(const Offset(68, 114), 1.8, j.palet.redup);

  // Jendela pelayanan + meja.
  j.kotak(const Rect.fromLTRB(88, 76, 156, 112), 3, tipis: true);
  j.garis(const Offset(84, 112), const Offset(160, 112));

  // Tiga toples di meja — tinggi berbeda supaya barisnya tidak terbaca sebagai
  // pagar.
  const toples = <(double, double)>[(96, 90), (116, 84), (136, 94)];
  for (final (x, atas) in toples) {
    j.kotak(Rect.fromLTRB(x, atas, x + 14, 110), 2.5, tipis: true);
    j.garis(
      Offset(x - 1, atas + 4),
      Offset(x + 15, atas + 4),
      tipis: true,
      warna: j.palet.redup,
    );
  }

  // Dua lampu gantung.
  for (final x in const [50.0, 150.0]) {
    j.garis(Offset(x, 60), Offset(x, 68), tipis: true, warna: j.palet.redup);
    j.bulat(Offset(x, 71), 3.4, tipis: true, warna: j.palet.redup);
  }
}

// ---------------------------------------------------------------------------
// 2 · Ponsel di satu tangan
// ---------------------------------------------------------------------------

void _kasir(_Juru j) {
  // Ponselnya dimiringkan sedikit. Tegak lurus terbaca seperti gambar spesifikasi
  // perangkat; sedikit miring terbaca seperti benda yang sedang dipegang.
  //
  // Tidak ada tangan yang digambar. Percobaan pertama memakai siluet jempol dan
  // hasilnya terbaca seperti kait, bukan tangan — bentuk organik menuntut
  // ketepatan yang tidak bisa dicapai dengan busur dan garis lurus. Gantinya
  // busur jangkauan DI DALAM layar: idiom yang sudah dikenal untuk "sejauh ini
  // yang bisa diraih satu tangan", dan seluruhnya geometris.
  j.kanvas
    ..save()
    ..translate(100, 74)
    ..rotate(-7 * math.pi / 180);

  const badan = Rect.fromLTRB(-40, -64, 40, 64);
  const layar = Rect.fromLTRB(-34, -57, 34, 57);
  j.kotak(badan, 12);
  j.kotak(layar, 8, tipis: true, warna: j.palet.redup);

  // Kepala layar: nama toko dan angka berjalan, diwakili dua goresan.
  j.garis(
    const Offset(-27, -47),
    const Offset(-5, -47),
    tipis: true,
    warna: j.palet.redup,
  );
  j.garis(
    const Offset(-27, -40),
    const Offset(-15, -40),
    tipis: true,
    warna: j.palet.redup,
  );

  // Petak produk 2×2. Satu di antaranya sedang disentuh — itu yang membuat
  // gambar ini bercerita, bukan sekadar memperlihatkan kisi kosong.
  const petak = <Rect>[
    Rect.fromLTRB(-27, -31, -4, -9),
    Rect.fromLTRB(4, -31, 27, -9),
    Rect.fromLTRB(-27, -3, -4, 19),
    Rect.fromLTRB(4, -3, 27, 19),
  ];
  const disentuh = 3;
  for (var i = 0; i < petak.length; i++) {
    if (i == disentuh) {
      j.kotakIsi(petak[i], 4, j.palet.tinta);
    } else {
      j.kotak(petak[i], 4, tipis: true, warna: j.palet.redup);
    }
  }

  // Bilah keranjang di kaki layar.
  j.kotakIsi(const Rect.fromLTRB(-27, 29, 27, 46), 5, j.palet.isian);
  j.garis(
    const Offset(-22, 37.5),
    const Offset(-7, 37.5),
    tipis: true,
    warna: j.palet.redup,
  );
  j.kotakIsi(const Rect.fromLTRB(6, 33, 23, 42), 4.5, j.palet.tinta);

  // Busur jangkauan, berpusat di sudut bawah-kanan layar. Jari-jarinya dipilih
  // supaya petak yang disentuh jatuh TEPAT di dalam busur — itu yang membuat
  // gambar ini menyampaikan sesuatu, bukan sekadar menghias.
  j.busurPutus(
    Rect.fromCircle(center: layar.bottomRight, radius: 58),
    math.pi,
    math.pi / 2,
    warna: j.palet.redup,
  );

  // Riak sentuh: dua busur, bukan lingkaran penuh. Lingkaran penuh terbaca
  // sebagai benda; busur terbaca sebagai gerakan.
  final pusatSentuh = petak[disentuh].center;
  for (final jari in const [16.0, 22.0]) {
    j.busurPutus(
      Rect.fromCircle(center: pusatSentuh, radius: jari),
      -math.pi * 0.92,
      math.pi * 0.84,
      warna: j.palet.redup,
    );
  }

  j.kanvas.restore();
}

// ---------------------------------------------------------------------------
// 3 · Rak stok
// ---------------------------------------------------------------------------

void _rak(_Juru j) {
  const kiri = 30.0, kanan = 158.0, atas = 24.0, bawah = 134.0;

  j.kotak(const Rect.fromLTRB(kiri, atas, kanan, bawah), 4);

  // Dua papan pemisah.
  for (final y in const [61.0, 98.0]) {
    j.garis(
      const Offset(kiri, 0).translate(0, y),
      const Offset(kanan, 0).translate(0, y),
    );
  }

  // Kaki rak — supaya benda ini berdiri, bukan menempel di udara.
  j.garis(const Offset(46, bawah), const Offset(46, 146));
  j.garis(const Offset(142, bawah), const Offset(142, 146));

  // Baris atas: penuh.
  for (final x in const [38.0, 66.0, 94.0, 122.0]) {
    j.kotak(
      Rect.fromLTRB(x, 34, x + 22, 59),
      2.5,
      tipis: true,
      warna: j.palet.redup,
    );
    j.garis(
      Offset(x + 4, 40),
      Offset(x + 18, 40),
      tipis: true,
      warna: j.palet.redup,
    );
  }

  // Baris tengah: satu slot sudah kosong. Keadaan yang membuat orang butuh
  // fitur ini memang keadaan buruk, bukan rak yang rapi.
  for (final x in const [38.0, 66.0, 94.0]) {
    j.kotak(
      Rect.fromLTRB(x, 70, x + 22, 96),
      2.5,
      tipis: true,
      warna: j.palet.redup,
    );
  }
  const kosong = Rect.fromLTRB(122, 70, 144, 96);
  j.garisPutus(kosong.topLeft, kosong.topRight);
  j.garisPutus(kosong.bottomLeft, kosong.bottomRight);
  j.garisPutus(kosong.topLeft, kosong.bottomLeft);
  j.garisPutus(kosong.topRight, kosong.bottomRight);

  // Baris bawah: toples bertutup.
  for (final x in const [38.0, 70.0, 102.0]) {
    j.kotak(
      Rect.fromLTRB(x, 106, x + 26, 132),
      3,
      tipis: true,
      warna: j.palet.redup,
    );
    j.garis(
      Offset(x + 2, 112),
      Offset(x + 24, 112),
      tipis: true,
      warna: j.palet.redup,
    );
  }

  // Panah turun di sisi kanan: stoknya berkurang sendiri setiap ada penjualan.
  const xPanah = 176.0;
  j.garis(const Offset(xPanah, 46), const Offset(xPanah, 104));
  final kepala = Path()
    ..moveTo(xPanah - 7, 96)
    ..lineTo(xPanah, 106)
    ..lineTo(xPanah + 7, 96);
  j.jalur(kepala);
}

// ---------------------------------------------------------------------------
// 4 · Laporan dan resep
// ---------------------------------------------------------------------------

void _laporan(_Juru j) {
  const panel = Rect.fromLTRB(22, 20, 158, 116);
  j.kotak(panel, 10);

  // Kepala panel: label kecil dan satu angka besar, diwakili dua bidang.
  j.kotakIsi(const Rect.fromLTRB(34, 32, 76, 37), 2.5, j.palet.isian);
  j.kotakIsi(const Rect.fromLTRB(34, 43, 108, 53), 3, j.palet.tinta);

  // Tujuh batang. Yang terakhir pejal — puncaknya, sekaligus alasan grafik ini
  // ada: yang dicari orang bukan bentuk kurvanya, tapi hari terbaiknya.
  const dasar = 100.0;
  const tinggi = <double>[16, 13, 24, 20, 30, 26, 40];
  const lebarBatang = 11.0;
  const jarakBatang = 6.0;
  const xMulai = 34.0;

  for (var i = 0; i < tinggi.length; i++) {
    final x = xMulai + i * (lebarBatang + jarakBatang);
    final r = Rect.fromLTRB(x, dasar - tinggi[i], x + lebarBatang, dasar);
    if (i == tinggi.length - 1) {
      j.kotakIsi(r, 2.5, j.palet.tinta);
    } else {
      j.kotakIsi(r, 2.5, j.palet.isian);
    }
  }
  j.garis(
    const Offset(30, dasar + 4),
    const Offset(150, dasar + 4),
    tipis: true,
    warna: j.palet.redup,
  );

  // Buku resep yang menyembul dari balik panel — "ikut sekalian" digambarkan
  // dengan tumpang tindih, bukan dengan tanda tambah.
  const buku = Rect.fromLTRB(120, 96, 180, 138);
  j.kotakIsi(buku, 6, j.palet.kertas);
  j.kotak(buku, 6);
  j.garis(
    const Offset(134, 96),
    const Offset(134, 138),
    tipis: true,
    warna: j.palet.redup,
  );
  for (final y in const [110.0, 119.0, 128.0]) {
    j.garis(
      Offset(142, y),
      Offset(y == 128.0 ? 160 : 170, y),
      tipis: true,
      warna: j.palet.redup,
    );
  }
}

// ---------------------------------------------------------------------------
// Motif latar
// ---------------------------------------------------------------------------

/// Anyaman garis miring yang sangat samar.
///
/// Dipakai di belakang kepala layar pertanyaan. Tugasnya bukan menghias tapi
/// memberi tekstur pada bidang yang kalau dibiarkan kosong terbaca seperti
/// layar yang belum selesai memuat. Opasitasnya sengaja di ambang terlihat —
/// begitu ia cukup jelas untuk diperhatikan, ia sudah terlalu kuat.
class MotifLatar extends StatelessWidget {
  const MotifLatar({super.key, this.tinggi = 132, required this.child});

  final double tinggi;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: tinggi,
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _PelukisMotif(
                garis: context.warna.onSurface,
                kertas: context.warna.surface,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PelukisMotif extends CustomPainter {
  _PelukisMotif({required this.garis, required this.kertas});

  final Color garis;
  final Color kertas;

  @override
  void paint(Canvas kanvas, Size ukuran) {
    const jarak = 16.0;
    final kuas = Paint()
      ..color = garis.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..isAntiAlias = true;

    // Diagonal 45°: digambar dari -tinggi supaya sudut kiri atas ikut tertutup.
    for (var x = -ukuran.height; x < ukuran.width; x += jarak) {
      kanvas.drawLine(
        Offset(x, 0),
        Offset(x + ukuran.height, ukuran.height),
        kuas,
      );
    }

    // Pudar ke bawah, supaya motif tidak bertabrakan dengan isi halaman.
    kanvas.drawRect(
      Offset.zero & ukuran,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kertas.withValues(alpha: 0), kertas],
          stops: const [0.35, 1],
        ).createShader(Offset.zero & ukuran),
    );
  }

  @override
  bool shouldRepaint(covariant _PelukisMotif lama) =>
      lama.garis != garis || lama.kertas != kertas;
}
