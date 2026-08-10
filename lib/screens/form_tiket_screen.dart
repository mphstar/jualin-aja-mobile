import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Halaman Form Pengiriman Tiket Saran & Komplain.
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
        title: const Text('Kirim Saran / Komplain'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Jarak.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Laporan',
                  style: context.teks.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Jarak.xs2),
                Wrap(
                  spacing: Jarak.xs,
                  children: [
                    ChoiceChip(
                      label: const Text('Saran Pengembangan'),
                      selected: _jenis == JenisTiket.saran,
                      onSelected: (v) {
                        if (v) setState(() => _jenis = JenisTiket.saran);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Komplain / Bug'),
                      selected: _jenis == JenisTiket.komplain,
                      onSelected: (v) {
                        if (v) setState(() => _jenis = JenisTiket.komplain);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Pertanyaan'),
                      selected: _jenis == JenisTiket.pertanyaan,
                      onSelected: (v) {
                        if (v) setState(() => _jenis = JenisTiket.pertanyaan);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: Jarak.md),

                TextFormField(
                  controller: _subjekCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Singkat / Subjek',
                    hintText: 'Mis. Usulan Tambahan Fitur Cetak Struk',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Subjek laporan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Jarak.md),

                TextFormField(
                  controller: _pesanCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Detail Pesan & Penjelasan',
                    hintText: 'Jelaskan saran fitur atau masalah yang Anda alami secara detail...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Detail pesan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Jarak.lg),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _mengirim ? null : _kirim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.warna.primary,
                      foregroundColor: context.warna.onPrimary,
                    ),
                    child: _mengirim
                        ? const CircularProgressIndicator.adaptive()
                        : const Text('Kirim Laporan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
