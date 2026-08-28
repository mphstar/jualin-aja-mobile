import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../data/api.dart' as api;
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/ilustrasi.dart';

/// Pratinjau PDF langsung di aplikasi — tanpa mengunduh lalu menyimpan berkas.
///
/// Berkas diambil ke memori (bytes) lalu dirender lewat [PdfDocument], jadi
/// tidak ada file yang tersimpan permanen di perangkat. Dipakai untuk resep
/// maupun prompt di Pustaka.
class BacaScreen extends StatefulWidget {
  const BacaScreen({super.key, required this.judul, required this.url});

  final String judul;
  final String url;

  @override
  State<BacaScreen> createState() => _BacaScreenState();
}

class _BacaScreenState extends State<BacaScreen> {
  PdfControllerPinch? _controller;
  bool _galat = false;
  int _halaman = 1;
  int _total = 1;

  @override
  void initState() {
    super.initState();
    _buka();
  }

  Future<void> _buka() async {
    try {
      final bytes = await api.getBytesUrl(widget.url);
      final doc = await PdfDocument.openData(bytes);
      if (!mounted) return;
      final total = doc.pagesCount;
      setState(() {
        _total = total;
        _controller = PdfControllerPinch(document: Future.value(doc));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _galat = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.judul,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_controller != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_halaman / $_total',
                  style: context.teks.labelMedium,
                ),
              ),
            ),
        ],
      ),
      body: _galat
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Jarak.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Ilustrasi(
                      gambar: GambarIlustrasi.laporan,
                      lebarMaks: 200,
                    ),
                    const SizedBox(height: Jarak.md),
                    Text(
                      'Gagal memuat berkas. Pastikan koneksi tersedia.',
                      textAlign: TextAlign.center,
                      style: context.teks.bodyMedium?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _controller == null
              ? const _PemuatBerkas()
              : PdfViewPinch(
                  controller: _controller!,
                  onPageChanged: (halaman) =>
                      setState(() => _halaman = halaman),
                ),
    );
  }
}

/// Pemuat berkas PDF yang lebih hidup daripada pemintal kosong.
///
/// Ilustrasi vektor + salinan singkat, dan denyut halus pada teks supaya
/// jelas bahwa sesuatu sedang terjadi — bukan layar yang menggantung.
class _PemuatBerkas extends StatefulWidget {
  const _PemuatBerkas();

  @override
  State<_PemuatBerkas> createState() => _PemuatBerkasState();
}

class _PemuatBerkasState extends State<_PemuatBerkas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _denyut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _denyut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Ilustrasi(
              gambar: GambarIlustrasi.laporan,
              lebarMaks: 200,
            ),
            const SizedBox(height: Jarak.md),
            AnimatedBuilder(
              animation: _denyut,
              builder: (context, child) {
                final double opasitas = Tween<double>(begin: 0.35, end: 1)
                    .evaluate(
                      CurvedAnimation(
                        parent: _denyut,
                        curve: Curves.easeInOut,
                      ),
                    );

                return Opacity(opacity: opasitas, child: child);
              },
              child: Text(
                'Menyiapkan berkas…',
                style: context.teks.bodyMedium?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
