import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/pilih_berkas.dart';
import '../util/simpan_berkas.dart';
import '../widgets/modal_fitur_terkunci.dart';
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
      final lokasi = await simpanBerkasKePerangkat(hasil.bytes, hasil.filename);
      if (!mounted) return;

      setState(() {
        _memprosesUnduh = false;
        _pesanSukses = 'Templat Excel tersimpan di folder Download ($lokasi).';
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
        _pesanGalat = _pesanGalatUnduh(e);
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
        _pesanGalat = _pesanGalatPilihBerkas(e);
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
        _pesanGalat = _pesanGalatImpor(e);
      });
    }
  }

  // -------------------------------------------------------------------------
  // Pesan galat ramah — JANGAN pernah menampilkan `$e` mentah (mis. "Permission
  // denied"). Pengguna hanya perlu tahu apa yang salah & apa yang harus
  // dilakukan, bukan nama kelas pengecualian.
  // -------------------------------------------------------------------------

  static bool _izinDitolak(Object e) {
    final teks = e.toString().toLowerCase();
    return teks.contains('permission') ||
        teks.contains('access is denied') ||
        teks.contains('denied');
  }

  String _pesanGalatUnduh(Object e) => _izinDitolak(e)
      ? 'Izin penyimpanan tidak diberikan. Berikan izin penyimpanan pada '
            'aplikasi, lalu coba lagi.'
      : 'Templat tidak berhasil diunduh. Periksa koneksi lalu coba lagi.';

  String _pesanGalatPilihBerkas(Object e) => _izinDitolak(e)
      ? 'Izin akses berkas tidak diberikan. Berikan izin pada aplikasi, lalu '
            'coba lagi.'
      : 'Berkas tidak bisa dipilih. Coba lagi.';

  String _pesanGalatImpor(Object e) => _izinDitolak(e)
      ? 'Izin akses berkas tidak diberikan. Berikan izin pada aplikasi, lalu '
            'coba lagi.'
      : 'Impor tidak berhasil. Periksa berkas lalu coba lagi.';

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final lebarLayar = MediaQuery.sizeOf(context).width;
    final lebarDialog = (lebarLayar - 48).clamp(260.0, 420.0);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Lengkung.panel),
      ),
      titlePadding: const EdgeInsets.fromLTRB(Jarak.md, Jarak.md, Jarak.md, 0),
      contentPadding: const EdgeInsets.fromLTRB(Jarak.md, Jarak.sm, Jarak.md, Jarak.xs),
      actionsPadding: const EdgeInsets.fromLTRB(Jarak.md, 0, Jarak.md, Jarak.sm),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.warna.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.upload_file_rounded,
              color: context.warna.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: Jarak.xs),
          Expanded(
            child: Text(
              'Impor Produk Excel',
              style: context.teks.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: lebarDialog,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unggah berkas Excel (.xlsx) atau CSV untuk menambah & memperbarui daftar produk secara massal.',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Jarak.sm),

              // Langkah 1: Format Templat
              Container(
                padding: const EdgeInsets.all(Jarak.xs),
                decoration: BoxDecoration(
                  color: context.warna.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  border: Border.all(color: context.warna.outline.withAlpha(100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: context.warna.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Format Templat Standard',
                            style: context.teks.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unduh contoh templat Excel (.xlsx) yang sudah disusun sesuai kolom aplikasi.',
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs2),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: _memprosesUnduh ? null : _unduhTemplat,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Lengkung.kecil),
                          ),
                        ),
                        icon: _memprosesUnduh
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_rounded, size: 16),
                        label: Text(
                          _memprosesUnduh ? 'Mengunduh…' : 'Unduh Format Excel (.xlsx)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Jarak.xs),

              // Langkah 2: Pilih & Unggah Berkas
              Container(
                padding: const EdgeInsets.all(Jarak.xs),
                decoration: BoxDecoration(
                  color: _namaBerkasTerpilih != null
                      ? a.suksesLembut
                      : context.warna.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  border: Border.all(
                    color: _namaBerkasTerpilih != null
                        ? a.sukses.withAlpha(120)
                        : context.warna.outline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _namaBerkasTerpilih != null
                                ? a.sukses
                                : context.warna.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilih Berkas (.xlsx / .csv)',
                            style: context.teks.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Jarak.xs2),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: _pilihBerkas,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _namaBerkasTerpilih != null
                              ? a.sukses
                              : context.warna.primary,
                          side: BorderSide(
                            color: _namaBerkasTerpilih != null
                                ? a.sukses
                                : context.warna.outline,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Lengkung.kecil),
                          ),
                        ),
                        icon: Icon(
                          _namaBerkasTerpilih != null
                              ? Icons.check_circle_rounded
                              : Icons.note_add_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _namaBerkasTerpilih ?? 'Pilih Berkas Excel/CSV',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_pesanGalat != null) ...[
                const SizedBox(height: Jarak.xs),
                Container(
                  padding: const EdgeInsets.all(Jarak.xs2),
                  decoration: BoxDecoration(
                    color: a.bahayaLembut,
                    borderRadius: BorderRadius.circular(Lengkung.kecil),
                    border: Border.all(color: a.bahaya.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 16, color: a.bahaya),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _pesanGalat!,
                          style: context.teks.bodySmall?.copyWith(
                            color: a.bahaya,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_pesanSukses != null) ...[
                const SizedBox(height: Jarak.xs),
                Container(
                  padding: const EdgeInsets.all(Jarak.xs2),
                  decoration: BoxDecoration(
                    color: a.suksesLembut,
                    borderRadius: BorderRadius.circular(Lengkung.kecil),
                    border: Border.all(color: a.sukses.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: a.sukses),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _pesanSukses!,
                          style: context.teks.bodySmall?.copyWith(
                            color: a.sukses,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_ringkasan != null) ...[
                const SizedBox(height: Jarak.xs2),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.warna.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(Lengkung.kecil),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Berhasil: ${_ringkasan!['berhasil'] ?? 0} produk',
                            style: context.teks.bodySmall?.copyWith(
                              color: a.sukses,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gagal: ${_ringkasan!['gagal'] ?? 0} baris',
                            style: context.teks.bodySmall?.copyWith(
                              color: (_ringkasan!['gagal'] ?? 0) > 0
                                  ? a.bahaya
                                  : context.warna.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if ((_ringkasan!['gagal'] ?? 0) > 0 &&
                          _ringkasan!['rincianGagal'] != null) ...[
                        const SizedBox(height: 6),
                        const Divider(height: 1),
                        const SizedBox(height: 6),
                        Text(
                          'Penyebab Gagal:',
                          style: context.teks.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: a.bahaya,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (_ringkasan!['rincianGagal'] as List).isNotEmpty
                              ? ((_ringkasan!['rincianGagal'][0] as Map)['alasan'] as String? ??
                                  'Batas kuota produk paket Gratis tercapai.')
                              : 'Batas kuota produk paket Gratis tercapai.',
                          style: context.teks.bodySmall?.copyWith(
                            color: context.warna.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ModalFiturTerkunci.tampilkan(
                                context,
                                jenis: JenisFiturTerkunci.batasProduk,
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: context.warna.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Lengkung.kecil),
                              ),
                            ),
                            icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                            label: const Text(
                              'Upgrade Langganan Sekarang',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
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
