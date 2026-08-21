import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../data/api.dart' as api;
import '../theme/app_theme.dart';

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
              child: Text(
                'Gagal memuat berkas. Pastikan koneksi tersedia.',
                style: context.teks.bodyMedium,
              ),
            )
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewPinch(
                  controller: _controller!,
                  onPageChanged: (halaman) =>
                      setState(() => _halaman = halaman),
                ),
    );
  }
}
