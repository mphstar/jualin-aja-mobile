import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'blok_foto.dart';

/// Modal bottom sheet atraktif & premium untuk konfirmasi penghapusan produk.
class ModalHapusProduk extends StatefulWidget {
  const ModalHapusProduk({
    super.key,
    required this.produk,
    this.namaKategori,
  });

  final Produk produk;
  final String? namaKategori;

  /// Membuka lembar modal konfirmasi hapus produk.
  /// Mengembalikan true jika produk berhasil dihapus.
  static Future<bool?> tampilkan(
    BuildContext context, {
    required Produk produk,
    String? namaKategori,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalHapusProduk(
        produk: produk,
        namaKategori: namaKategori,
      ),
    );
  }

  @override
  State<ModalHapusProduk> createState() => _ModalHapusProdukState();
}

class _ModalHapusProdukState extends State<ModalHapusProduk> {
  bool _menghapus = false;
  String? _galat;

  Future<void> _prosesHapus() async {
    setState(() {
      _menghapus = true;
      _galat = null;
    });

    try {
      await Repositori.hapusProduk(widget.produk.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menghapus = false;
        _galat = e.pesan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final produk = widget.produk;

    return Container(
      decoration: BoxDecoration(
        color: context.warna.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Lengkung.panel),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Jarak.md,
        Jarak.sm,
        Jarak.md,
        MediaQuery.of(context).padding.bottom + Jarak.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pegangan bilah atas
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.warna.onSurfaceVariant.withAlpha(76),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Jarak.md),

          // Spanduk Peringatan Bahaya dengan Glow Badging
          Container(
            padding: const EdgeInsets.all(Jarak.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  a.bahaya.withAlpha(25),
                  context.warna.surfaceContainerHigh,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Lengkung.kontrol),
              border: Border.all(
                color: a.bahaya.withAlpha(80),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: a.bahaya,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: a.bahaya.withAlpha(90),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: context.warna.onError,
                    size: 28,
                  ),
                ),
                const SizedBox(width: Jarak.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hapus Produk?',
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: a.bahaya,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: Jarak.xs3),
                      Text(
                        'Aksi ini permanen dan tidak dapat dibatalkan.',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Jarak.md),

          // Ringkasan Kartu Produk yang Akan Dihapus
          Container(
            padding: const EdgeInsets.all(Jarak.xs),
            decoration: BoxDecoration(
              color: context.warna.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(Lengkung.kontrol),
              border: Border.all(color: context.warna.outline),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: BlokFoto(url: produk.gambarUrl, tampilkanLabel: false),
                ),
                const SizedBox(width: Jarak.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produk.nama,
                        style: context.teks.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.namaKategori != null
                            ? '${widget.namaKategori} · ${rupiah(produk.hargaJual)}'
                            : rupiah(produk.hargaJual),
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Jarak.sm),

          // Catatan Keamanan Struk
          Container(
            padding: const EdgeInsets.all(Jarak.xs),
            decoration: BoxDecoration(
              color: context.warna.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Lengkung.kontrol),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: context.warna.onSurfaceVariant,
                ),
                const SizedBox(width: Jarak.xs2),
                Expanded(
                  child: Text(
                    'Struk & riwayat transaksi terdahulu yang memuat produk ini tetap aman.',
                    style: context.teks.bodySmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_galat != null) ...[
            const SizedBox(height: Jarak.xs),
            Text(
              _galat!,
              style: context.teks.bodySmall?.copyWith(color: a.bahaya),
            ),
          ],

          const SizedBox(height: Jarak.md),

          // Tombol Aksi Hapus Red & Batal
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _menghapus ? null : _prosesHapus,
              style: FilledButton.styleFrom(
                backgroundColor: a.bahaya,
                foregroundColor: context.warna.onError,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: _menghapus
                  ? const SizedBox.shrink()
                  : const Icon(Icons.delete_forever, size: 20),
              label: _menghapus
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.warna.onError,
                      ),
                    )
                  : const Text('Ya, Hapus Produk'),
            ),
          ),
          const SizedBox(height: Jarak.xs2),

          Center(
            child: TextButton(
              onPressed: _menghapus ? null : () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: context.warna.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
