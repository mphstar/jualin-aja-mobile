import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/kartu.dart';
import '../widgets/lencana.dart';

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

class _StatusBayarScreenState extends State<StatusBayarScreen> {
  late Tagihan _tagihan = widget.tagihan;
  bool _memeriksa = false;
  String? _galat;
  Timer? _pemantauTimer;

  @override
  void initState() {
    super.initState();
    _mulaiPemantauanOtomatis();
  }

  @override
  void dispose() {
    _pemantauTimer?.cancel();
    super.dispose();
  }

  void _mulaiPemantauanOtomatis() {
    if (_tagihan.statusKini != StatusBayar.menunggu) return;
    _pemantauTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_memeriksa || !mounted || _tagihan.statusKini != StatusBayar.menunggu) return;
      try {
        final hasil = await Repositori.periksaTagihan(_tagihan);
        if (!mounted) return;
        if (hasil.statusKini != StatusBayar.menunggu) {
          _pemantauTimer?.cancel();
          setState(() {
            _tagihan = hasil;
            _galat = null;
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _periksa() async {
    setState(() {
      _memeriksa = true;
      _galat = null;
    });
    try {
      final hasil = await Repositori.periksaTagihan(_tagihan);
      if (!mounted) return;
      setState(() {
        _tagihan = hasil;
        _memeriksa = false;
        // Masih menunggu setelah diperiksa bukan galat — dana memang belum
        // masuk. Mengatakannya terus terang lebih baik daripada memutar
        // pemintal lalu diam.
        _galat = hasil.statusKini == StatusBayar.menunggu
            ? 'Pembayaran belum terdeteksi. Kalau baru saja membayar, '
                  'coba lagi beberapa menit lagi.'
            : null;
      });
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _memeriksa = false;
        _galat = e.pesan;
      });
    }
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
                ? 'Langganan aktif sampai ${tanggal(tagihan.berlakuSampai)}'
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
    final qrUrl = tagihan.instruksi?.qrUrl;
    final adaQr = qrUrl != null && qrUrl.isNotEmpty;

    if (adaQr) {
      return _PetakQr(tagihan: tagihan, qrUrl: qrUrl);
    }

    // Jatuh ke halaman hosted Mayar — cadangan ketika instrumen tak dikenal.
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
                        ? 'Pembayaran dilakukan di halaman Mayar.'
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
/// hitung mundur sampai kode berhenti berlaku.
class _PetakQr extends StatelessWidget {
  const _PetakQr({required this.tagihan, required this.qrUrl});

  final Tagihan tagihan;
  final String qrUrl;

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
                  child: Image.network(
                    qrUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const CircularProgressIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                          color: context.warna.onSurfaceVariant,
                        ),
                        const SizedBox(height: Jarak.xs2),
                        Text(
                          'Gagal memuat kode QR.',
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
            Icons.workspace_premium_outlined,
            size: 22,
            color: context.warna.onSurfaceVariant,
          ),
          judul: tagihan.durasi.label,
          keterangan: 'Berlaku sampai ${tanggal(tagihan.berlakuSampai)}',
          akhiran: rupiah(tagihan.nominal),
        ),
        BarisDaftar(
          awalan: Icon(
            Icons.payments_outlined,
            size: 22,
            color: context.warna.onSurfaceVariant,
          ),
          judul: 'Mayar',
          keterangan: 'Diproses oleh Mayar',
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