import 'package:flutter/material.dart';

import '../data/contoh.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/ilustrasi.dart';
import '../widgets/peraga.dart';
import '../widgets/tombol_pil.dart';

/// Layar masuk.
///
/// Registernya menyambung langsung dari alur pembuka: kertas lapang, judul
/// besar rata kiri, satu tombol pil tinta. Mengganti nada tepat di titik
/// pengguna diminta mengetik akan terasa seperti pindah aplikasi.
///
/// Di layar lebar formulirnya berdampingan dengan bidang identitas. Bukan demi
/// simetri: formulir 400 px yang mengambang sendirian di tengah layar 1400 px
/// tidak terbaca sebagai halaman, ia terbaca sebagai dialog yang lupa ditutup.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onMasuk, this.onKembali});

  final VoidCallback onMasuk;

  /// Null berarti tidak ada tempat untuk mundur — layar masuk sedang jadi
  /// layar pertama, bukan lanjutan dari alur pembuka.
  final VoidCallback? onKembali;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _kunciForm = GlobalKey<FormState>();
  final _email = TextEditingController(text: kredensialDemo.email);
  final _sandi = TextEditingController(text: kredensialDemo.sandi);
  bool _lihatSandi = false;
  bool _memproses = false;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    setState(() => _galat = null);
    if (!_kunciForm.currentState!.validate()) return;

    setState(() => _memproses = true);

    try {
      await Repositori.masuk(
        email: _email.text.trim(),
        kataSandi: _sandi.text,
      );
      if (!mounted) return;
      widget.onMasuk();
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
      // Tanda merek duduk di chrome, bukan di badan formulir. Di badan ia
      // mendorong tombol Masuk keluar layar pada ponsel 568 px — dan tombol
      // utama yang harus digulir dulu adalah kegagalan, bukan gaya.
      appBar: AppBar(
        titleSpacing: widget.onKembali == null ? Jarak.sm : 0,
        leading: widget.onKembali == null
            ? null
            : IconButton(
                onPressed: widget.onKembali,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
              ),
        title: const TandaMerek(ukuran: 34, berlabel: true),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, batas) {
            final berdampingan = batas.maxWidth >= 900;

            // Ilustrasi hanya muncul kalau tingginya memang cukup. Di ponsel
            // 568 px ia akan mendorong tombol Masuk ke bawah lipatan, dan
            // tombol utama yang harus digulir dulu adalah kegagalan, bukan
            // gaya. Di layar berdampingan ia sudah diwakili bidang identitas.
            final adaRuang = !berdampingan && batas.maxHeight >= 600;

            final formulir = Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Jarak.md,
                  Jarak.sm,
                  Jarak.md,
                  Jarak.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buatFormulir(context, denganIlustrasi: adaRuang),
                ),
              ),
            );

            if (!berdampingan) return formulir;

            return Row(
              children: [
                const Expanded(flex: 5, child: _BidangIdentitas()),
                Expanded(flex: 6, child: formulir),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buatFormulir(BuildContext context, {required bool denganIlustrasi}) {
    return Form(
      key: _kunciForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (denganIlustrasi) ...[
            const Ilustrasi(gambar: GambarIlustrasi.etalase, lebarMaks: 236),
            const SizedBox(height: Jarak.xs),
          ],
          Text('Masuk ke\ntoko Anda', style: context.teks.displaySmall),
          const SizedBox(height: Jarak.xs2),
          Text(
            'Satu akun untuk satu toko.',
            style: context.teks.bodyMedium?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Jarak.lg),

          const _Label('Email'),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'nama@toko.id'),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Masukkan email yang benar.'
                : null,
          ),
          const SizedBox(height: Jarak.sm),

          const _Label('Kata sandi'),
          TextFormField(
            controller: _sandi,
            obscureText: !_lihatSandi,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _masuk(),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _lihatSandi = !_lihatSandi),
                icon: Icon(
                  _lihatSandi ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                tooltip: _lihatSandi
                    ? 'Sembunyikan kata sandi'
                    : 'Tampilkan kata sandi',
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Kata sandi wajib diisi.' : null,
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
          TombolPil(label: 'Masuk', memproses: _memproses, onTekan: _masuk),
          const SizedBox(height: Jarak.xs2),
          Align(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: context.warna.onSurfaceVariant,
              ),
              child: const Text('Lupa kata sandi?'),
            ),
          ),

          const SizedBox(height: Jarak.md),
          const _KartuDemo(),
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

/// Bidang identitas untuk layar lebar — etalase dan janji produk, gambar yang
/// sama dengan yang dilihat pengguna ponsel tepat di atas formulirnya.
class _BidangIdentitas extends StatelessWidget {
  const _BidangIdentitas();

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
                'Catat\npenjualan,\nbukan kertas',
                style: context.teks.displaySmall,
              ),
              const SizedBox(height: Jarak.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  'Transaksi, stok, laporan harian, dan katalog resep — '
                  'dalam satu aplikasi untuk satu toko.',
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

class _KartuDemo extends StatelessWidget {
  const _KartuDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.aksen.kartuAlt,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akun demo',
            style: context.teks.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${kredensialDemo.email} · ${kredensialDemo.sandi}',
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada autentikasi sungguhan — kredensialnya sengaja terlihat.',
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
