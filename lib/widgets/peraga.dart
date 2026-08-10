import 'package:flutter/material.dart';

import '../data/backdoor.dart';
import '../screens/backdoor_screen.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Tanda merek dan penunjuk langkah untuk alur pembuka.
///
/// Berkas ini pernah juga berisi tiga "peraga": replika struk, kartu stok, dan
/// panel omzet yang dibangun dari widget layar sungguhan. Gagasannya benar —
/// layar pembuka memperagakan produk, bukan menunggu foto — tapi hasilnya
/// terbaca seperti tangkapan layar yang dikecilkan, bukan seperti gambar.
///
/// Penggantinya ada di `ilustrasi.dart`: ilustrasi garis yang boleh
/// melebih-lebihkan yang penting dan membuang sisanya. Aturannya tidak berubah,
/// hanya cara memenuhinya: tetap monokrom, tetap menggambarkan janji slide-nya,
/// dan tetap tidak pernah memamerkan penanda foto kosong.

// ---------------------------------------------------------------------------
// Tanda merek
// ---------------------------------------------------------------------------

/// Logo resmi dari `assets/logo.png`, dengan wordmark opsional.
///
/// Satu bentuk yang sama dipakai di kepala rail, layar masuk, dan layar daftar,
/// jadi perpindahan dari luar ke dalam aplikasi membawa satu benda yang
/// dikenali.
class TandaMerek extends StatelessWidget {
  const TandaMerek({super.key, this.ukuran = 44, this.berlabel = false});

  final double ukuran;
  final bool berlabel;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/logo.png',
      width: ukuran,
      height: ukuran,
      fit: BoxFit.contain,
    );

    if (!berlabel) return logo;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: Jarak.xs2),
        Flexible(
          child: Text(
            'JualinAja',
            style: context.teks.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Logo yang boleh diketuk sepuluh kali untuk membuka backdoor debug.
///
/// Dipakai di layar pra-mulai (onboarding, masuk, daftar) dan kepala aplikasi.
/// Ketukan tidak harus berurutan; total sepuluh ketukan sudah cukup. Setelah
/// itu diminta kata sandi ([kataSandiBackdoor]) sebelum layar backdoor terbuka.
class TandaMerekBackdoor extends StatefulWidget {
  const TandaMerekBackdoor({super.key, this.ukuran = 44, this.berlabel = false});

  final double ukuran;
  final bool berlabel;

  @override
  State<TandaMerekBackdoor> createState() => _TandaMerekBackdoorState();
}

class _TandaMerekBackdoorState extends State<TandaMerekBackdoor> {
  int _ketukan = 0;

  void _ketuk() {
    _ketukan++;
    if (_ketukan >= 10) {
      _ketukan = 0;
      _bukaBackdoor();
    }
  }

  Future<void> _bukaBackdoor() async {
    final sandi = await _mintaKataSandi();
    if (sandi == null || !mounted) return;

    if (sandi != kataSandiBackdoor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi backdoor salah.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BackdoorScreen()),
    );
  }

  Future<String?> _mintaKataSandi() {
    final pengendali = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backdoor debug'),
        content: TextField(
          controller: pengendali,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kata sandi',
            hintText: 'Masukkan kata sandi backdoor',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(pengendali.text),
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _ketuk,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Area ketuk sedikit diluaskan supaya sepuluh ketukan cepat mudah
        // dikenali, tanpa mengubah posisi logo di layar.
        padding: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
        child: TandaMerek(ukuran: widget.ukuran, berlabel: widget.berlabel),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Penunjuk langkah
// ---------------------------------------------------------------------------

/// Penunjuk langkah untuk layar pertanyaan.
///
/// Tanpa ini, dua layar pertanyaan yang bentuknya mirip terbaca seperti satu
/// layar yang gagal berpindah — dan pengguna tidak punya cara tahu apakah
/// masih ada sepuluh lagi di depan.
class PenunjukLangkah extends StatelessWidget {
  const PenunjukLangkah({super.key, required this.langkah, required this.dari});

  final int langkah;
  final int dari;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= dari; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: Gerak.sedang,
              curve: Gerak.keluar,
              height: 4,
              decoration: BoxDecoration(
                color: i <= langkah
                    ? context.warna.onSurface
                    : context.aksen.isian,
                borderRadius: BorderRadius.circular(Lengkung.bulat),
              ),
            ),
          ),
        ],
        const SizedBox(width: Jarak.xs),
        Text(
          '$langkah/$dari',
          style: context.teks.labelSmall?.copyWith(
            color: context.warna.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
