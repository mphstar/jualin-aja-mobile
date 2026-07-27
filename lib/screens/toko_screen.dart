import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/bingkai.dart';
import '../widgets/kartu.dart';
import '../widgets/rangka.dart';
import '../widgets/tombol_pil.dart';

/// Data toko.
///
/// Isinya sedikit dan sengaja: nama, jenis usaha, alamat, telepon. Keempatnya
/// punya satu pemakai bersama — struk. Menambahkan field yang tidak dicetak di
/// mana pun berarti meminta pemilik toko mengisi sesuatu yang tidak pernah
/// dipakai.
class TokoScreen extends StatelessWidget {
  const TokoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data toko')),
      body: SafeArea(
        top: false,
        child: Bingkai<Toko>(
          ambil: Repositori.toko,
          rangka: const Padding(
            padding: EdgeInsets.all(Jarak.sm),
            child: Column(
              children: [
                RangkaPanel(tinggi: 96),
                SizedBox(height: Jarak.md),
              ],
            ),
          ),
          isi: (context, toko) => _Formulir(awal: toko),
        ),
      ),
    );
  }
}

class _Formulir extends StatefulWidget {
  const _Formulir({required this.awal});

  final Toko awal;

  @override
  State<_Formulir> createState() => _FormulirState();
}

class _FormulirState extends State<_Formulir> {
  final _kunciForm = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _alamat;
  late final TextEditingController _telepon;
  late String _jenis;

  bool _menyimpan = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.awal.nama);
    _alamat = TextEditingController(text: widget.awal.alamat);
    _telepon = TextEditingController(text: widget.awal.telepon);
    // Jenis usaha yang tidak dikenali daftar (mis. data lama) tidak dibuang
    // diam-diam; ia jatuh ke "Lainnya" supaya pilihannya tetap terlihat benar.
    _jenis = jenisUsahaPilihan.contains(widget.awal.jenisUsaha)
        ? widget.awal.jenisUsaha
        : jenisUsahaPilihan.last;
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _telepon.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_kunciForm.currentState!.validate()) return;

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      await Repositori.simpanToko(
        widget.awal.salin(
          nama: _nama.text.trim(),
          jenisUsaha: _jenis,
          alamat: _alamat.text.trim(),
          telepon: _telepon.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Data toko disimpan')));
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = e.pesan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _kunciForm,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Jarak.sm,
                    Jarak.xs,
                    Jarak.sm,
                    Jarak.sm,
                  ),
                  children: [
                    _CatatanStruk(nama: _nama.text.trim()),
                    const SizedBox(height: Jarak.md),

                    const JudulBagian('Identitas'),
                    TextFormField(
                      controller: _nama,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Nama toko',
                        hintText: 'Mis. Kopi Senja',
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Nama toko wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: Jarak.sm),
                    Text(
                      'Jenis usaha',
                      style: context.teks.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs2),
                    Wrap(
                      spacing: Jarak.xs2,
                      runSpacing: Jarak.xs2,
                      children: [
                        for (final j in jenisUsahaPilihan)
                          ChoiceChip(
                            label: Text(j),
                            selected: _jenis == j,
                            onSelected: (_) => setState(() => _jenis = j),
                          ),
                      ],
                    ),

                    const SizedBox(height: Jarak.md),
                    const JudulBagian('Kontak'),
                    TextFormField(
                      controller: _alamat,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        hintText: 'Jalan, nomor, kota',
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Alamat wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: Jarak.sm),
                    TextFormField(
                      controller: _telepon,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        hintText: '08xx-xxxx-xxxx',
                      ),
                      validator: (v) => (v == null || v.trim().length < 8)
                          ? 'Nomor telepon wajib diisi.'
                          : null,
                    ),

                    if (_galat != null) ...[
                      const SizedBox(height: Jarak.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: context.aksen.bahaya,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _galat!,
                              style: context.teks.bodySmall?.copyWith(
                                color: context.aksen.bahaya,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Jarak.sm,
                  0,
                  Jarak.sm,
                  Jarak.sm,
                ),
                child: TombolPil(
                  label: 'Simpan',
                  memproses: _menyimpan,
                  onTekan: _menyimpan ? null : _simpan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pengingat bahwa data ini bukan sekadar profil.
///
/// Tanpa kalimat ini, "Data toko" terbaca seperti halaman biodata yang boleh
/// dilewati — padahal isinya yang tercetak di kepala setiap struk.
class _CatatanStruk extends StatelessWidget {
  const _CatatanStruk({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.aksen.kartuAlt,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: context.warna.onSurfaceVariant,
          ),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              nama.isEmpty
                  ? 'Data ini tercetak di kepala setiap struk.'
                  : 'Tercetak di kepala setiap struk, di atas nama '
                        '"$nama".',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
