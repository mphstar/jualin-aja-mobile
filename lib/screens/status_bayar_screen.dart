import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// karena ia sedang berpindah ke aplikasi bank lalu kembali.
///
/// Karena itu keadaan menunggu dirancang untuk **ditinggalkan dan didatangi
/// lagi**: nomor VA bisa disalin sekali ketuk, batas waktunya tertulis sebagai
/// tanggal dan jam (bukan hitung mundur detik yang tidak berguna pada jendela
/// 24 jam), dan tombol "Saya sudah bayar" ada di tempat yang sama saat orang
/// kembali.
///
/// Saat Midtrans disambung, status sungguhannya datang lewat **webhook** ke
/// backend, bukan dari pengguna menekan tombol. Tombol itu tetap ada sebagai
/// pemicu pemeriksaan ulang — pengguna yang sudah membayar tapi belum melihat
/// perubahan butuh sesuatu untuk ditekan.
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
                    _Instruksi(tagihan: _tagihan),
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

/// Instruksi bergantung saluran.
class _Instruksi extends StatelessWidget {
  const _Instruksi({required this.tagihan});

  final Tagihan tagihan;

  @override
  Widget build(BuildContext context) {
    if (tagihan.saluran.pakaiKode) {
      return _KodeVa(
        bank: tagihan.saluran.label,
        kode: tagihan.kodeBayar ?? '—',
        kodePerusahaan: tagihan.saluran == SaluranBayar.vaMandiri
            ? (tagihan.kodePerusahaan ?? '70012')
            : null,
      );
    }
    return _PetakQris(tagihan: tagihan);
  }
}

class _KodeVa extends StatelessWidget {
  const _KodeVa({
    required this.bank,
    required this.kode,
    this.kodePerusahaan,
  });

  final String bank;
  final String kode;
  final String? kodePerusahaan;

  @override
  Widget build(BuildContext context) {
    final mandiri = kodePerusahaan != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              bank,
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            if (mandiri) ...[
              Text(
                'Kode Perusahaan (Biller Code)',
                style: context.teks.labelSmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kodePerusahaan!,
                      style: context.teks.titleLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: kodePerusahaan!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Kode Perusahaan disalin.')),
                        );
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Salin'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: Jarak.xs),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Jarak.xs),
              Text(
                'Kode Bayar (Bill Key)',
                style: context.teks.labelSmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      kode,
                      style: context.teks.titleLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Jarak.xs2),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: kode));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            mandiri ? 'Kode Bayar disalin.' : 'Nomor VA disalin.',
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Salin'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: Jarak.xs),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Jarak.xs),
            Divider(height: 1, color: context.warna.outline),
            const SizedBox(height: Jarak.xs),
            for (final (i, langkah) in (mandiri
                ? const [
                    'Buka aplikasi Livin\' by Mandiri atau ATM Mandiri.',
                    'Pilih menu Bayar / Multipayment.',
                    'Masukkan Kode Perusahaan & Kode Bayar di atas.',
                  ]
                : const [
                    'Buka aplikasi bank atau ATM.',
                    'Pilih menu Transfer ke Virtual Account.',
                    'Masukkan nomor di atas, lalu bayar sesuai nominal.',
                  ]).indexed) ...[
              if (i > 0) const SizedBox(height: 6),
              _Langkah(nomor: i + 1, teks: langkah),
            ],
          ],
        ),
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({required this.nomor, required this.teks});

  final int nomor;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Text(
            '$nomor.',
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            teks,
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tempat kode QR.
class _PetakQris extends StatelessWidget {
  const _PetakQris({required this.tagihan});

  final Tagihan tagihan;

  @override
  Widget build(BuildContext context) {
    final saluran = tagihan.saluran;
    final adaQr = tagihan.qrUrl != null && tagihan.qrUrl!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: adaQr ? 220 : 176,
              decoration: BoxDecoration(
                color: context.aksen.kartuAlt,
                borderRadius: BorderRadius.circular(Lengkung.kontrol),
                border: Border.all(color: context.aksen.garisRedup),
              ),
              alignment: Alignment.center,
              child: adaQr
                  ? Padding(
                      padding: const EdgeInsets.all(Jarak.xs),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Lengkung.kontrol),
                        child: Image.network(
                          tagihan.qrUrl!,
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
                                'Gagal memuat QR Code.',
                                style: context.teks.bodySmall?.copyWith(
                                  color: context.warna.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          saluran == SaluranBayar.qris
                              ? Icons.qr_code_2
                              : Icons.account_balance_wallet_outlined,
                          size: 36,
                          color: context.warna.onSurfaceVariant,
                        ),
                        const SizedBox(height: Jarak.xs2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
                          child: Text(
                            saluran == SaluranBayar.qris
                                ? 'Kode QR dibuat Midtrans saat backend tersambung.'
                                : 'Tautan pembayaran GoPay dibuat Midtrans saat '
                                      'backend tersambung.',
                            textAlign: TextAlign.center,
                            style: context.teks.bodySmall?.copyWith(
                              color: context.warna.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: Jarak.xs),
            Text(
              saluran == SaluranBayar.qris
                  ? 'Pindai dengan aplikasi bank atau e-wallet apa pun yang '
                        'mendukung QRIS.'
                  : 'Pindai dengan aplikasi Gojek atau gunakan tautan pembayaran GoPay.',
              textAlign: TextAlign.center,
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (adaQr) ...[
              const SizedBox(height: Jarak.xs),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: tagihan.qrUrl!));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Tautan gambar QR disalin ke papan klip.'),
                      ),
                    );
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Salin Tautan Gambar QR'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
            if (tagihan.tautanBayar != null && tagihan.tautanBayar!.isNotEmpty) ...[
              const SizedBox(height: Jarak.xs2),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: tagihan.tautanBayar!));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Tautan pembayaran GoPay disalin.'),
                      ),
                    );
                },
                icon: const Icon(Icons.link_outlined, size: 16),
                label: const Text('Salin Tautan GoPay'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
          judul: tagihan.saluran.label,
          keterangan: 'Diproses oleh Midtrans',
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
