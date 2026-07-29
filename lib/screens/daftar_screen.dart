import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/ilustrasi.dart';
import '../widgets/peraga.dart';
import '../widgets/tombol_pil.dart';

/// Layar pendaftaran mandiri toko baru.
class DaftarScreen extends StatefulWidget {
  const DaftarScreen({super.key, required this.onBerhasilDaftar, required this.onMasuk});

  final VoidCallback onBerhasilDaftar;
  final VoidCallback onMasuk;

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  final _kunciForm = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _telepon = TextEditingController();
  final _namaToko = TextEditingController();
  final _kota = TextEditingController();
  final _kataSandi = TextEditingController();
  final _konfirmasiSandi = TextEditingController();

  String _jenisUsaha = 'KAFE';
  bool _lihatSandi = false;
  bool _lihatKonfirmasi = false;
  bool _memproses = false;
  String? _galat;

  static const _pilihanJenisUsaha = <String, String>{
    'KAFE': 'Kafe',
    'RESTORAN': 'Restoran',
    'WARUNG_MAKAN': 'Warung Makan',
    'BAKERY': 'Bakery',
    'TOKO_KELONTONG': 'Toko Kelontong',
    'LAINNYA': 'Lainnya',
  };

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _telepon.dispose();
    _namaToko.dispose();
    _kota.dispose();
    _kataSandi.dispose();
    _konfirmasiSandi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    setState(() => _galat = null);
    if (!_kunciForm.currentState!.validate()) return;

    setState(() => _memproses = true);

    try {
      await Repositori.daftar(
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        telepon: _telepon.text.trim(),
        namaToko: _namaToko.text.trim(),
        jenisUsaha: _jenisUsaha,
        kota: _kota.text.trim(),
        kataSandi: _kataSandi.text,
        kataSandiKonfirmasi: _konfirmasiSandi.text,
      );
      if (!mounted) return;
      widget.onBerhasilDaftar();
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _memproses = false;
        _galat = e.pesan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onMasuk,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali ke Masuk',
        ),
        title: const TandaMerek(ukuran: 34, berlabel: true),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, batas) {
            final berdampingan = batas.maxWidth >= 900;

            final formulir = Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Jarak.md,
                  Jarak.sm,
                  Jarak.md,
                  Jarak.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buatFormulir(context),
                ),
              ),
            );

            if (!berdampingan) return formulir;

            return Row(
              children: [
                const Expanded(flex: 5, child: _BidangIdentitasDaftar()),
                Expanded(flex: 6, child: formulir),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buatFormulir(BuildContext context) {
    return Form(
      key: _kunciForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Buat Akun Toko', style: context.teks.displaySmall),
          const SizedBox(height: Jarak.xs2),
          Text(
            'Daftar gratis dan nikmati trial 3 hari full fitur.',
            style: context.teks.bodyMedium?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Jarak.lg),

          const _Label('Nama Pemilik'),
          TextFormField(
            controller: _nama,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Nama lengkap Anda'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi.' : null,
          ),
          const SizedBox(height: Jarak.sm),

          const _Label('Email Toko'),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'nama@toko.id'),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Masukkan email yang benar.'
                : null,
          ),
          const SizedBox(height: Jarak.sm),

          const _Label('Nomor Telepon / WhatsApp'),
          TextFormField(
            controller: _telepon,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: '08123456789'),
            validator: (v) =>
                (v == null || v.trim().length < 8) ? 'Masukkan nomor telepon yang sah.' : null,
          ),
          const SizedBox(height: Jarak.sm),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Nama Toko'),
                    TextFormField(
                      controller: _namaToko,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'Kedai Kopi'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama toko wajib diisi.'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Kota'),
                    TextFormField(
                      controller: _kota,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'Surabaya'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Kota wajib diisi.' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.sm),

          const _Label('Jenis Usaha'),
          DropdownButtonFormField<String>(
            initialValue: _jenisUsaha,
            decoration: const InputDecoration(),
            items: _pilihanJenisUsaha.entries.map((e) {
              return DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _jenisUsaha = val);
            },
          ),
          const SizedBox(height: Jarak.sm),

          const _Label('Kata Sandi'),
          TextFormField(
            controller: _kataSandi,
            obscureText: !_lihatSandi,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Minimal 8 karakter',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _lihatSandi = !_lihatSandi),
                icon: Icon(
                  _lihatSandi ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
              ),
            ),
            validator: (v) => (v == null || v.length < 8)
                ? 'Kata sandi minimal 8 karakter.'
                : null,
          ),
          const SizedBox(height: Jarak.sm),

          const _Label('Konfirmasi Kata Sandi'),
          TextFormField(
            controller: _konfirmasiSandi,
            obscureText: !_lihatKonfirmasi,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _daftar(),
            decoration: InputDecoration(
              hintText: 'Ulangi kata sandi',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _lihatKonfirmasi = !_lihatKonfirmasi),
                icon: Icon(
                  _lihatKonfirmasi ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
              if (v != _kataSandi.text) return 'Konfirmasi kata sandi tidak cocok.';
              return null;
            },
          ),

          if (_galat != null) ...[
            const SizedBox(height: Jarak.xs),
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

          const SizedBox(height: Jarak.md),
          TombolPil(label: 'Daftar Sekarang', memproses: _memproses, onTekan: _daftar),
          const SizedBox(height: Jarak.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sudah punya akun? ',
                style: context.teks.bodyMedium?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: widget.onMasuk,
                child: Text(
                  'Masuk di sini',
                  style: context.teks.bodyMedium?.copyWith(
                    color: context.warna.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        teks,
        style: context.teks.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BidangIdentitasDaftar extends StatelessWidget {
  const _BidangIdentitasDaftar();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.aksen.kartuAlt,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Jarak.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Ilustrasi(gambar: GambarIlustrasi.etalase, lebarMaks: 320),
              const SizedBox(height: Jarak.lg),
              Text(
                'Mulai bisnis Anda\nhari ini',
                style: context.teks.displaySmall,
              ),
              const SizedBox(height: Jarak.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  'Kelola penjualan, kasir, dan laporan usaha Anda dengan mudah. Bebas biaya pendaftaran dan langsung aktif.',
                  style: context.teks.bodyMedium?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
