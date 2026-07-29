import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/pilih_berkas.dart';
import '../util/simpan_berkas.dart';
import '../widgets/tombol_pil.dart';

/// Dialog modal untuk mengunduh templat format Excel (.xlsx),
/// memilih berkas, dan mengimpor daftar produk secara massal.
class DialogImporProduk extends StatefulWidget {
  const DialogImporProduk({super.key});

  static Future<void> tampilkan(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const DialogImporProduk(),
    );
  }

  @override
  State<DialogImporProduk> createState() => _DialogImporProdukState();
}

class _DialogImporProdukState extends State<DialogImporProduk> {
  bool _memprosesUnduh = false;
  bool _memprosesImpor = false;
  String? _namaBerkasTerpilih;
  Uint8List? _bytesBerkas;

  String? _pesanSukses;
  String? _pesanGalat;
  Map<String, dynamic>? _ringkasan;

  Future<void> _unduhTemplat() async {
    setState(() {
      _memprosesUnduh = true;
      _pesanGalat = null;
    });

    try {
      final hasil = await Repositori.unduhFormatImporProduk();
      await simpanBerkasKePerangkat(hasil.bytes, hasil.filename);
      if (!mounted) return;

      setState(() {
        _memprosesUnduh = false;
        _pesanSukses = 'Templat format Excel berhasil diunduh (${hasil.filename}).';
      });
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _memprosesUnduh = false;
        _pesanGalat = e.pesan;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memprosesUnduh = false;
        _pesanGalat = 'Gagal mengunduh format templat: $e';
      });
    }
  }

  Future<void> _pilihBerkas() async {
    setState(() {
      _pesanGalat = null;
      _pesanSukses = null;
    });

    try {
      final hasil = await pilihBerkasExcel();
      if (hasil != null) {
        setState(() {
          _namaBerkasTerpilih = hasil.filename;
          _bytesBerkas = hasil.bytes;
        });
      }
    } catch (e) {
      setState(() {
        _pesanGalat = 'Gagal memilih berkas: $e';
      });
    }
  }

  Future<void> _kirimImpor() async {
    if (_bytesBerkas == null || _namaBerkasTerpilih == null) return;

    setState(() {
      _memprosesImpor = true;
      _pesanGalat = null;
      _pesanSukses = null;
      _ringkasan = null;
    });

    try {
      final hasil = await Repositori.imporProduk(
        _bytesBerkas!,
        _namaBerkasTerpilih!,
      );

      if (!mounted) return;
      setState(() {
        _memprosesImpor = false;
        _ringkasan = hasil;
        _pesanSukses = hasil['pesan'] as String? ?? 'Impor berhasil diproses.';
      });
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _memprosesImpor = false;
        _pesanGalat = e.pesan;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memprosesImpor = false;
        _pesanGalat = 'Terjadi kesalahan saat mengimpor: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.upload_file, size: 24),
          SizedBox(width: Jarak.xs),
          Text('Impor Data Produk Excel'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unggah berkas Excel (.xlsx) atau CSV untuk menambah dan memperbarui data produk secara massal.',
                style: context.teks.bodyMedium?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Jarak.md),

              // Langkah 1: Unduh Templat
              Container(
                padding: const EdgeInsets.all(Jarak.sm),
                decoration: BoxDecoration(
                  color: context.aksen.kartuAlt,
                  borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  border: Border.all(color: context.warna.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Format Templat Excel',
                      style: context.teks.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gunakan format templat standar (.xlsx) yang menyertakan contoh data.',
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs),
                    OutlinedButton.icon(
                      onPressed: _memprosesUnduh ? null : _unduhTemplat,
                      icon: _memprosesUnduh
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(_memprosesUnduh ? 'Mengunduh…' : 'Unduh Format Templat (.xlsx)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Jarak.md),

              // Langkah 2: Pilih & Unggah Berkas
              Container(
                padding: const EdgeInsets.all(Jarak.sm),
                decoration: BoxDecoration(
                  color: context.warna.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  border: Border.all(color: context.warna.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2. Pilih Berkas Excel/CSV',
                      style: context.teks.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pilihBerkas,
                            icon: const Icon(Icons.file_open, size: 18),
                            label: Text(
                              _namaBerkasTerpilih ?? 'Pilih Berkas (.xlsx / .csv)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_pesanGalat != null) ...[
                const SizedBox(height: Jarak.sm),
                Container(
                  padding: const EdgeInsets.all(Jarak.xs),
                  decoration: BoxDecoration(
                    color: context.aksen.bahayaLembut,
                    borderRadius: BorderRadius.circular(Lengkung.kecil),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: context.aksen.bahaya),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _pesanGalat!,
                          style: context.teks.bodySmall?.copyWith(
                            color: context.aksen.bahaya,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_pesanSukses != null) ...[
                const SizedBox(height: Jarak.sm),
                Container(
                  padding: const EdgeInsets.all(Jarak.xs),
                  decoration: BoxDecoration(
                    color: context.aksen.suksesLembut,
                    borderRadius: BorderRadius.circular(Lengkung.kecil),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: context.aksen.sukses),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _pesanSukses!,
                          style: context.teks.bodySmall?.copyWith(
                            color: context.aksen.sukses,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_ringkasan != null) ...[
                const SizedBox(height: Jarak.xs),
                Text(
                  'Berhasil: ${_ringkasan!['berhasil']} produk | Gagal: ${_ringkasan!['gagal']} baris',
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_ringkasan != null ? 'Selesai' : 'Batal'),
        ),
        if (_bytesBerkas != null && _ringkasan == null)
          TombolPil(
            label: 'Impor Sekarang',
            memproses: _memprosesImpor,
            onTekan: _kirimImpor,
          ),
      ],
    );
  }
}
