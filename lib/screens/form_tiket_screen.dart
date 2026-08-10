import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Halaman Form Pengiriman Tiket Saran & Komplain (Redesigned & Premium UI).
class FormTiketScreen extends StatefulWidget {
  const FormTiketScreen({super.key});

  @override
  State<FormTiketScreen> createState() => _FormTiketScreenState();
}

class _FormTiketScreenState extends State<FormTiketScreen> {
  final _formKey = GlobalKey<FormState>();
  JenisTiket _jenis = JenisTiket.saran;
  final _subjekCtrl = TextEditingController();
  final _pesanCtrl = TextEditingController();
  bool _mengirim = false;

  @override
  void dispose() {
    _subjekCtrl.dispose();
    _pesanCtrl.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _mengirim = true);
    try {
      await Repositori.buatTiket(
        jenis: _jenis,
        subjek: _subjekCtrl.text.trim(),
        pesan: _pesanCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Gagal mengirim tiket: $e')),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _mengirim = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan / Saran'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Jarak.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Informasi
                Container(
                  padding: const EdgeInsets.all(Jarak.md),
                  decoration: BoxDecoration(
                    color: context.warna.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(Lengkung.panel),
                    border: Border.all(color: context.warna.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.warna.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.connect_without_contact_rounded,
                          color: context.warna.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: Jarak.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kami Siap Mendengar',
                              style: context.teks.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: Jarak.xs3),
                            Text(
                              'Kirim saran pengembangan atau laporkan kendala. Tim admin akan menanggapi langsung.',
                              style: context.teks.bodySmall?.copyWith(
                                color: context.warna.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Jarak.md),

                // Kategori Selector Visual
                Text(
                  'Kategori Laporan',
                  style: context.teks.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Jarak.xs2),
                Column(
                  children: [
                    _KartuPilihanKategori(
                      judul: 'Saran Pengembangan',
                      keterangan: 'Ide fitur baru atau usulan perbaikan antarmuka',
                      ikon: Icons.lightbulb_outlined,
                      warnaAksen: Colors.indigo,
                      terpilih: _jenis == JenisTiket.saran,
                      onTap: () => setState(() => _jenis = JenisTiket.saran),
                    ),
                    const SizedBox(height: Jarak.xs2),
                    _KartuPilihanKategori(
                      judul: 'Komplain / Bug',
                      keterangan: 'Laporan masalah, eror, atau kendala transaksi',
                      ikon: Icons.bug_report_outlined,
                      warnaAksen: const Color(0xFFF43F5E),
                      terpilih: _jenis == JenisTiket.komplain,
                      onTap: () => setState(() => _jenis = JenisTiket.komplain),
                    ),
                    const SizedBox(height: Jarak.xs2),
                    _KartuPilihanKategori(
                      judul: 'Pertanyaan Bantuan',
                      keterangan: 'Pertanyaan seputar panduan & fitur aplikasi',
                      ikon: Icons.help_outline_rounded,
                      warnaAksen: Colors.amber.shade800,
                      terpilih: _jenis == JenisTiket.pertanyaan,
                      onTap: () => setState(() => _jenis = JenisTiket.pertanyaan),
                    ),
                  ],
                ),
                const SizedBox(height: Jarak.md),

                // Field Subjek
                Text(
                  'Subjek Laporan',
                  style: context.teks.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Jarak.xs2),
                TextFormField(
                  controller: _subjekCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ringkasan singkat masukan atau masalah Anda',
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: context.warna.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: context.warna.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                      borderSide: BorderSide(color: context.warna.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                      borderSide: BorderSide(color: context.warna.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                      borderSide: BorderSide(color: context.warna.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Subjek laporan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Jarak.md),

                // Field Pesan
                Text(
                  'Detail Penjelasan',
                  style: context.teks.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Jarak.xs2),
                TextFormField(
                  controller: _pesanCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Jelaskan secara rinci saran fitur atau langkah kejadian kendala yang Anda alami...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: context.warna.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                      borderSide: BorderSide(color: context.warna.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                      borderSide: BorderSide(color: context.warna.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Lengkung.kontrol),
                      borderSide: BorderSide(color: context.warna.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Detail pesan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Jarak.lg),

                // Tombol Kirim Utama
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Lengkung.bulat),
                    boxShadow: Bayangan.mengambang,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _mengirim ? null : _kirim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.warna.primary,
                      foregroundColor: context.warna.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Lengkung.bulat),
                      ),
                      elevation: 0,
                    ),
                    icon: _mengirim
                        ? const SizedBox.shrink()
                        : const Icon(Icons.send_rounded, size: 20),
                    label: _mengirim
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Laporan Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: Jarak.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuPilihanKategori extends StatelessWidget {
  const _KartuPilihanKategori({
    required this.judul,
    required this.keterangan,
    required this.ikon,
    required this.warnaAksen,
    required this.terpilih,
    required this.onTap,
  });

  final String judul;
  final String keterangan;
  final IconData ikon;
  final Color warnaAksen;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: terpilih
            ? warnaAksen.withValues(alpha: 0.08)
            : context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(
          color: terpilih ? warnaAksen : context.warna.outlineVariant,
          width: terpilih ? 1.8 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Jarak.md,
            vertical: Jarak.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: warnaAksen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: warnaAksen, size: 22),
              ),
              const SizedBox(width: Jarak.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: context.teks.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: terpilih ? warnaAksen : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      keterangan,
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (terpilih)
                Icon(
                  Icons.check_circle_rounded,
                  color: warnaAksen,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
