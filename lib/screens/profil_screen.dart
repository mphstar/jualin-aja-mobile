import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/bingkai.dart';
import '../widgets/isian_uang.dart' show BarisGalat;
import '../widgets/kartu.dart';
import '../widgets/rangka.dart';
import '../widgets/tombol_pil.dart';

/// Ubah profil pemilik.
///
/// Sengaja BUKAN halaman yang sama dengan Data toko, walau keduanya sama-sama
/// berisi nama dan telepon. Yang di sini tidak pernah tercetak di struk dan
/// tidak pernah dilihat pembeli — ia identitas orangnya. Menggabung keduanya
/// membuat "ganti nomor HP saya" diam-diam mengganti nomor yang tercetak di
/// setiap struk hari itu.
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah profil')),
      body: SafeArea(
        top: false,
        child: Bingkai<Profil>(
          ambil: Repositori.profil,
          rangka: const Padding(
            padding: EdgeInsets.all(Jarak.sm),
            child: Column(
              children: [
                RangkaPanel(tinggi: 96),
                SizedBox(height: Jarak.md),
                RangkaDaftar(baris: 3),
              ],
            ),
          ),
          isi: (context, profil) => _Formulir(awal: profil),
        ),
      ),
    );
  }
}

class _Formulir extends StatefulWidget {
  const _Formulir({required this.awal});

  final Profil awal;

  @override
  State<_Formulir> createState() => _FormulirState();
}

class _FormulirState extends State<_Formulir> {
  final _kunciForm = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _email;
  late final TextEditingController _telepon;

  bool _menyimpan = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.awal.nama);
    _email = TextEditingController(text: widget.awal.email);
    _telepon = TextEditingController(text: widget.awal.telepon);
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
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
      await Repositori.simpanProfil(
        widget.awal.salin(
          nama: _nama.text.trim(),
          email: _email.text.trim(),
          telepon: _telepon.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profil disimpan')));
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
                    // Avatarnya ikut berubah sambil nama diketik. Inisial yang
                    // baru berubah setelah disimpan membuat orang mengira
                    // gantinya tidak masuk.
                    _Avatar(nama: _nama.text, peran: widget.awal.peran),
                    const SizedBox(height: Jarak.md),

                    const JudulBagian('Identitas'),
                    TextFormField(
                      controller: _nama,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        hintText: 'Mis. Bintang Pratama',
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Nama wajib diisi.'
                          : null,
                    ),

                    const SizedBox(height: Jarak.md),
                    const JudulBagian('Kontak'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@toko.id',
                      ),
                      validator: (v) => _emailSah(v ?? '')
                          ? null
                          : 'Masukkan email yang benar.',
                    ),
                    const SizedBox(height: Jarak.sm),
                    TextFormField(
                      controller: _telepon,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _simpan(),
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        hintText: '08xx-xxxx-xxxx',
                      ),
                      validator: (v) => (v == null || v.trim().length < 8)
                          ? 'Nomor telepon wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: Jarak.xs2),
                    const _CatatanEmail(),

                    if (_galat != null) ...[
                      const SizedBox(height: Jarak.sm),
                      BarisGalat(pesan: _galat!),
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
                  label: 'Simpan perubahan',
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

  /// Sengaja longgar. Pemeriksa email yang ketat menolak alamat sah yang aneh
  /// dan tetap meloloskan alamat yang tidak ada — yang benar-benar memastikan
  /// hanya surat verifikasi, dan itu urusan backend.
  static bool _emailSah(String nilai) {
    final teks = nilai.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(teks);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nama, required this.peran});

  final String nama;
  final String peran;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final terisi = nama.trim().isNotEmpty;

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: a.fokus, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: terisi
              ? Text(
                  inisial(nama),
                  style: context.teks.titleLarge?.copyWith(color: a.atasFokus),
                )
              : Icon(Icons.person_outline, color: a.atasFokus),
        ),
        const SizedBox(width: Jarak.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                terisi ? nama.trim() : 'Tanpa nama',
                style: context.teks.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                peran,
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Email bukan sekadar kontak — ia yang dipakai untuk masuk. Tanpa kalimat ini,
/// menggantinya terasa seperti menyunting biodata, sampai orang gagal masuk
/// besok pagi dan tidak tahu kenapa.
class _CatatanEmail extends StatelessWidget {
  const _CatatanEmail();

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
            Icons.lock_outline,
            size: 20,
            color: context.warna.onSurfaceVariant,
          ),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              'Email ini yang dipakai untuk masuk. Data toko yang tercetak di '
              'struk diatur terpisah, di Akun · Data toko.',
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
