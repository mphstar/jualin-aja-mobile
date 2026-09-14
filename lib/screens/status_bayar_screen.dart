import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/klaim.dart';
import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../util/gagal_galeri.dart';
import '../util/kartu_qris.dart';
import '../util/simpan_galeri.dart';
import '../widgets/kartu.dart';
import '../widgets/lencana.dart';
import 'klaim_pustaka_screen.dart';

/// Layar setelah tagihan dibuat.
///
/// Empat keadaan, semuanya nyata: **menunggu · lunas · gagal · kedaluwarsa**
/// (PRD M6 F6.2). Yang paling sering terlewat saat membangun adalah keadaan
/// pertama — dan justru di situlah pengguna menghabiskan waktu paling lama,
/// karena ia sedang membayar di halaman Mayar lalu kembali.
///
/// Karena itu keadaan menunggu dirancang untuk **ditinggalkan dan didatangi
/// lagi**: halaman pembayaran Mayar dibuka lewat tombol besar, batas waktunya
/// tertulis sebagai tanggal dan jam (bukan hitung mundur detik yang tidak
/// berguna pada jendela 24 jam), dan tombol "Saya sudah bayar" ada di tempat
/// yang sama saat orang kembali.
///
/// Status sungguhannya datang lewat **webhook** ke backend, bukan dari
/// pengguna menekan tombol. Tombol itu tetap ada sebagai pemicu pemeriksaan
/// ulang — pengguna yang sudah membayar tapi belum melihat perubahan butuh
/// sesuatu untuk ditekan.
class StatusBayarScreen extends StatefulWidget {
  const StatusBayarScreen({super.key, required this.tagihan});

  final Tagihan tagihan;

  @override
  State<StatusBayarScreen> createState() => _StatusBayarScreenState();
}

class _StatusBayarScreenState extends State<StatusBayarScreen>
    with WidgetsBindingObserver {
  late Tagihan _tagihan = widget.tagihan;
  bool _memeriksa = false;
  String? _galat;
  Timer? _pemantauTimer;

  /// Pengalihan ke layar klaim hanya boleh terjadi sekali. Status tagihan
  /// diperiksa berulang tiap beberapa detik; tanpa penanda ini layar klaim
  /// akan ditumpuk berkali-kali di atas dirinya sendiri.
  bool _sudahDiarahkan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mulaiPemantauanOtomatis();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pemantauTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _periksaOtomatis();
    }
  }

  void _mulaiPemantauanOtomatis() {
    if (_tagihan.statusKini != StatusBayar.menunggu) return;
    _pemantauTimer?.cancel();
    _pemantauTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _periksaOtomatis();
    });
  }

  Future<void> _periksaOtomatis() async {
    if (!mounted || _tagihan.statusKini != StatusBayar.menunggu || _memeriksa) return;
    try {
      final hasil = await Repositori.periksaTagihan(_tagihan);
      if (!mounted) return;
      if (hasil.statusKini != StatusBayar.menunggu) {
        _pemantauTimer?.cancel();
        _terapkan(hasil);
      }
    } catch (_) {}
  }

  Future<void> _periksa() async {
    setState(() {
      _memeriksa = true;
      _galat = null;
    });
    try {
      final hasil = await Repositori.periksaTagihan(_tagihan);
      if (!mounted) return;

      // Pengalihan menang atas pesan apa pun: kalau tagihannya lunas, layar ini
      // memang akan ditinggalkan.
      if (_terapkan(hasil, galat: _pesanBelumTerbayar(hasil))) return;
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() => _galat = e.pesan);
    } finally {
      // Selalu: pemintal tidak boleh terus berputar di layar yang sudah
      // digantikan layar klaim.
      if (mounted) setState(() => _memeriksa = false);
    }
  }

  /// Terapkan tagihan terbaru — dan alihkan ke layar klaim bila pembayaran
  /// **langganannya** baru saja lunas.
  ///
  /// Pemeriksaannya ada di sini, bukan di tiap pemanggil: status tagihan
  /// diperiksa dari dua jalur (pemantauan berkala dan tombol "Saya sudah
  /// bayar"), dan aturan yang ditulis dua kali cepat atau lambat akan berbeda.
  ///
  /// Kembaliannya `true` kalau layar ini dialihkan; pemanggil tidak boleh
  /// melanjutkan `setState` setelahnya.
  bool _terapkan(Tagihan hasil, {String? galat}) {
    // `isCurrent` menahan pengalihan yang menimpa layar lain yang kebetulan
    // sedang di atas — mis. pratinjau PDF yang dibuka dari sini.
    if (perluKeHalamanKlaim(hasil, sudahDiarahkan: _sudahDiarahkan) &&
        ModalRoute.of(context)?.isCurrent == true) {
      _sudahDiarahkan = true;

      // `pushReplacement`, bukan `push`: layar ini sudah selesai tugasnya.
      // Tombol kembali perangkat dari layar klaim harus mengembalikan ke
      // langganan, bukan ke instruksi pembayaran yang sudah tidak berlaku.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const KlaimPustakaScreen()),
      );
      return true;
    }

    setState(() {
      _tagihan = hasil;
      _galat = galat;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final status = _tagihan.statusKini;
    final selesai = status == StatusBayar.lunas;

    return PopScope(
      // Selesai berarti tidak ada lagi yang bisa dibatalkan; tombol kembali
      // perangkat harus menutup layar ini, bukan mengembalikan orang ke
      // instruksi pembayaran yang sudah tidak berlaku.
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(selesai ? Icons.close : Icons.arrow_back),
            tooltip: selesai ? 'Tutup' : 'Kembali',
          ),
          title: const Text('Pembayaran'),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(Jarak.sm),
                children: [
                  _PanelStatus(tagihan: _tagihan),
                  const SizedBox(height: Jarak.md),

                  if (status == StatusBayar.menunggu) ...[
                    const JudulBagian('Cara membayar'),
                    _Instrumen(tagihan: _tagihan),
                    const SizedBox(height: Jarak.md),
                  ],

                  const JudulBagian('Rincian tagihan'),
                  _Rincian(tagihan: _tagihan),

                  if (_galat != null) ...[
                    const SizedBox(height: Jarak.xs),
                    _Catatan(pesan: _galat!),
                  ],

                  const SizedBox(height: Jarak.md),
                  ..._aksi(context, status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _aksi(BuildContext context, StatusBayar status) {
    return switch (status) {
      StatusBayar.menunggu => [
        FilledButton(
          onPressed: _memeriksa ? null : _periksa,
          child: _memeriksa
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.warna.onPrimary,
                  ),
                )
              : const Text('Saya sudah bayar'),
        ),
        const SizedBox(height: Jarak.xs2),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Bayar nanti'),
        ),
        const SizedBox(height: Jarak.xs2),
        Text(
          'Tagihan tetap tersimpan. Anda bisa kembali ke sini dari '
          'Akun · Riwayat pembayaran.',
          textAlign: TextAlign.center,
          style: context.teks.bodySmall?.copyWith(
            color: context.warna.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
      StatusBayar.lunas => [
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Selesai'),
        ),
      ],
      StatusBayar.gagal || StatusBayar.kedaluwarsa => [
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Buat tagihan baru'),
        ),
      ],
    };
  }
}

// ---------------------------------------------------------------------------

/// Pesan setelah diperiksa tapi tagihannya masih menunggu.
///
/// Bukan galat — dana memang belum masuk. Mengatakannya terus terang lebih
/// baik daripada memutar pemintal lalu diam.
String? _pesanBelumTerbayar(Tagihan tagihan) =>
    tagihan.statusKini == StatusBayar.menunggu
    ? 'Pembayaran belum terdeteksi. Kalau baru saja membayar, '
          'coba lagi beberapa menit lagi.'
    : null;

/// Kalimat keadaan lunas — berbeda menurut apa yang dibeli.
///
/// Pembelian konten Pustaka tidak punya `berlakuSampai`: yang dibeli akses
/// permanen, bukan masa berlaku. Menanyakan tanggalnya di situ dulu
/// menghasilkan "Langganan aktif sampai hari ini".
String _kalimatLunas(Tagihan tagihan) {
  if (tagihan.tipe.pustaka) return 'Konten terbuka untuk selamanya';

  final sampai = tagihan.berlakuSampai;
  if (sampai == null) return 'Pembayaran berhasil';

  return 'Langganan aktif sampai ${tanggal(sampai)}';
}

class _PanelStatus extends StatelessWidget {
  const _PanelStatus({required this.tagihan});

  final Tagihan tagihan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final status = tagihan.statusKini;
    final lunas = status == StatusBayar.lunas;

    final (ikon, warna) = switch (status) {
      StatusBayar.lunas => (Icons.check_circle, a.sukses),
      StatusBayar.menunggu => (Icons.schedule, a.peringatan),
      StatusBayar.gagal => (Icons.error_outline, a.bahaya),
      StatusBayar.kedaluwarsa => (Icons.timer_off_outlined, a.bahaya),
    };

    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: a.fokus,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        boxShadow: a.bayanganKartu,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(ikon, size: 20, color: warna),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status.label,
                  style: context.teks.labelSmall?.copyWith(
                    color: warna,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.xs2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(tagihan.nominal),
              style: context.teks.displaySmall?.copyWith(
                color: a.atasFokus,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: Jarak.xs2),
          Text(
            lunas
                ? _kalimatLunas(tagihan)
                : status == StatusBayar.menunggu
                ? 'Bayar sebelum ${tanggal(tagihan.batasBayar)}, '
                      '${jam(tagihan.batasBayar)}'
                : 'Tagihan ini tidak berlaku lagi',
            style: context.teks.bodyMedium?.copyWith(color: a.atasFokusRedup),
          ),
        ],
      ),
    );
  }
}

/// Instrumen pembayaran native — kode QR sekarang, VA/e-wallet menyusul.
///
/// Instrumen adalah soal tampilan, bukan bukti bayar; buktinya hanya status
/// `paid` yang terbaca ulang server. Kalau instrumen tidak dikenal, jatuh ke
/// tautan hosted Mayar.
class _Instrumen extends StatelessWidget {
  const _Instrumen({required this.tagihan});

  final Tagihan tagihan;

  Future<void> _buka(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final qrString = tagihan.instruksi?.qrString;
    final adaQr = qrString != null && qrString.isNotEmpty;

    if (adaQr) {
      return _PetakQr(tagihan: tagihan, qrString: qrString);
    }

    // Jatuh ke halaman pembayaran hosted — cadangan ketika instrumen tak dikenal.
    final url = tagihan.tautanBayar;
    final ada = url != null && url.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: context.warna.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ada
                        ? 'Pembayaran dilakukan di halaman pembayaran JualinAja.'
                        : 'Tautan pembayaran belum tersedia. Coba periksa kembali.',
                    style: context.teks.bodySmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (ada) ...[
              const SizedBox(height: Jarak.xs),
              FilledButton.icon(
                onPressed: () => _buka(context, url),
                icon: const Icon(Icons.launch, size: 18),
                label: const Text('Buka halaman pembayaran'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kode QR yang digambar langsung di aplikasi (native checkout), dengan
/// hitung mundur sampai kode berhenti berlaku dan tombol simpan ke galeri.
///
/// Kodenya digambar dari `qrString`, bukan diambil sebagai gambar dari server —
/// muatan QRIS tidak perlu keluar dari aplikasi.
class _PetakQr extends StatefulWidget {
  const _PetakQr({required this.tagihan, required this.qrString});

  final Tagihan tagihan;
  final String qrString;

  @override
  State<_PetakQr> createState() => _PetakQrState();
}

class _PetakQrState extends State<_PetakQr> {
  bool _mengunduh = false;

  Tagihan get tagihan => widget.tagihan;

  /// Nama berkas di galeri. Nomor invoice memuat garis miring (`INV/2026/0130`)
  /// yang tidak cocok jadi nama berkas.
  String get _namaBerkas =>
      'qris-${tagihan.nomorInvoice.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}';

  Future<void> _unduh() async {
    if (_mengunduh) return;
    setState(() => _mengunduh = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await gambarQris(tagihan, widget.qrString);
      await simpanGambarKeGaleri(bytes, _namaBerkas);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Gambar QRIS tersimpan di galeri.')),
        );
    } on GagalGaleri catch (e) {
      // Pesannya sudah disusun lapisan util — pengecualian platform mentah
      // tidak pernah sampai ke layar.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Gambar QRIS tidak berhasil disimpan. Coba lagi.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _mengunduh = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: context.aksen.kartuAlt,
                borderRadius: BorderRadius.circular(Lengkung.kontrol),
                border: Border.all(color: context.aksen.garisRedup),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(Jarak.xs),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  child: QrImageView(
                    data: widget.qrString,
                    version: QrVersions.auto,
                    gapless: true,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (context, error) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                          color: context.warna.onSurfaceVariant,
                        ),
                        const SizedBox(height: Jarak.xs2),
                        Text(
                          'Gagal menggambar kode QR.',
                          style: context.teks.bodySmall?.copyWith(
                            color: context.warna.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Jarak.xs),
            _HitungMundur(batas: tagihan.batasBayar),
            const SizedBox(height: Jarak.xs),
            Text(
              'Pindai dengan aplikasi bank atau e-wallet apa pun yang '
              'mendukung QRIS.',
              textAlign: TextAlign.center,
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            // Web tidak punya galeri foto yang bisa ditulis tab biasa — `gal`
            // memang tidak mendukungnya. Tombolnya disembunyikan daripada
            // disediakan tapi selalu gagal.
            if (galeriDidukung) ...[
              const SizedBox(height: Jarak.xs),
              OutlinedButton.icon(
                onPressed: _mengunduh ? null : _unduh,
                icon: _mengunduh
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: const Text('Simpan gambar QRIS'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hitung mundur menuju batas kode QR — kode berhenti tanpa suara, jadi
/// angkanya harus terlihat.
class _HitungMundur extends StatefulWidget {
  const _HitungMundur({required this.batas});

  final DateTime batas;

  @override
  State<_HitungMundur> createState() => _HitungMundurState();
}

class _HitungMundurState extends State<_HitungMundur> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sisa = widget.batas.difference(DateTime.now());
    final habis = sisa.isNegative;

    final teks = habis
        ? 'Kode QR sudah tidak berlaku.'
        : 'Berlaku sisa ${_menit(sisa)}';

    return Text(
      teks,
      textAlign: TextAlign.center,
      style: context.teks.labelLarge?.copyWith(
        color: habis ? context.aksen.bahaya : context.aksen.peringatan,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  String _menit(Duration sisa) {
    final total = sisa.inSeconds.clamp(0, 359999);
    final m = total ~/ 60;
    final d = total % 60;
    return '$m:${d.toString().padLeft(2, '0')}';
  }
}

class _Rincian extends StatelessWidget {
  const _Rincian({required this.tagihan});

  final Tagihan tagihan;

  @override
  Widget build(BuildContext context) {
    final pustaka = tagihan.tipe.pustaka;
    final berlakuSampai = tagihan.berlakuSampai;

    return KartuDaftar(
      anak: [
        BarisDaftar(
          awalan: Icon(
            Icons.receipt_long_outlined,
            size: 22,
            color: context.warna.onSurfaceVariant,
          ),
          judul: tagihan.nomorInvoice,
          keterangan: '${tanggal(tagihan.dibuat)} · ${jam(tagihan.dibuat)}',
          bawahAkhiran: _LencanaBayar(status: tagihan.statusKini),
        ),
        BarisDaftar(
          awalan: Icon(
            pustaka
                ? Icons.menu_book_outlined
                : Icons.workspace_premium_outlined,
            size: 22,
            color: context.warna.onSurfaceVariant,
          ),
          // `durasi` tagihan Pustaka hanya placeholder dari server (kolomnya
          // NOT NULL di sana) — menampilkannya berarti menjanjikan "1 Bulan"
          // untuk pembelian yang sebenarnya permanen.
          judul: pustaka ? tagihan.tipe.label : tagihan.durasi.label,
          keterangan: pustaka
              ? 'Akses permanen'
              : berlakuSampai == null
              ? 'Masa berlaku mengikuti paket'
              : 'Berlaku sampai ${tanggal(berlakuSampai)}',
          akhiran: rupiah(tagihan.nominal),
        ),
        BarisDaftar(
          awalan: Icon(
            Icons.payments_outlined,
            size: 22,
            color: context.warna.onSurfaceVariant,
          ),
          judul: 'JualinAja',
          keterangan: 'Pembayaran diverifikasi otomatis',
        ),
      ],
    );
  }
}

/// Lencana status pembayaran. Memakai nada yang sama dengan lencana langganan
/// supaya "menunggu" berwarna sama di mana pun ia muncul.
class LencanaBayar extends StatelessWidget {
  const LencanaBayar({super.key, required this.status});

  final StatusBayar status;

  @override
  Widget build(BuildContext context) => _LencanaBayar(status: status);
}

class _LencanaBayar extends StatelessWidget {
  const _LencanaBayar({required this.status});

  final StatusBayar status;

  @override
  Widget build(BuildContext context) {
    final (label, nada) = switch (status) {
      StatusBayar.lunas => ('Lunas', NadaLencana.sukses),
      StatusBayar.menunggu => ('Menunggu', NadaLencana.peringatan),
      StatusBayar.gagal => ('Gagal', NadaLencana.bahaya),
      StatusBayar.kedaluwarsa => ('Kedaluwarsa', NadaLencana.netral),
    };
    return Lencana(label, nada: nada);
  }
}

class _Catatan extends StatelessWidget {
  const _Catatan({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.aksen.peringatanLembut,
        borderRadius: BorderRadius.circular(Lengkung.kecil),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: context.aksen.peringatan),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pesan,
              style: context.teks.bodySmall?.copyWith(
                color: context.aksen.peringatan,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}