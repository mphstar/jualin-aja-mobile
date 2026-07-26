/* Hallmark · redesign (dari nol) · genre: modern-minimal · sistem: design.md
 * varian mobile: monokrom — aksi = tinta, kroma HANYA status
 * macrostructure: Focus-Panel (Beranda) · Catalog-Grid (Kasir) · Report (Laporan)
 *                 Split (Masuk) · Carousel + Question-Cards (Sambutan)
 * nav: N3 rail responsif · 5 tujuan · Riwayat jadi tab di dalam Laporan
 * enrichment: grafik batang dibangun tangan (Tier A) + BlokFoto berlabel
 * PRD: §1 empat tugas mobile · §4.1–4.3 aturan langganan · §8 empat keadaan
 * pre-emit critique: P5 H5 E5 S5 R5 V4
 */
import 'package:flutter/material.dart';

import 'screens/akun_screen.dart';
import 'screens/beranda_screen.dart';
import 'screens/kasir_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/login_screen.dart';
import 'screens/produk_screen.dart';
import 'screens/resep_screen.dart';
import 'screens/sambutan_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

void main() => runApp(const AplikasiPos());

class AplikasiPos extends StatefulWidget {
  const AplikasiPos({super.key});

  @override
  State<AplikasiPos> createState() => _AplikasiPosState();
}

/// Tiga tahap sebelum aplikasi sesungguhnya terbuka.
///
/// Dipisah jadi enum, bukan dua boolean, supaya keadaan mustahil seperti
/// "sudah masuk tapi masih di alur pembuka" tidak bisa diwakili sama sekali.
enum _Tahap { sambutan, masuk, aplikasi }

class _AplikasiPosState extends State<AplikasiPos> {
  // Tahap tampilan: tema dan sesi dipegang di sini saja. Saat state management
  // dipilih, ini yang pertama pindah — tidak ada layar yang bergantung padanya.
  ThemeMode _mode = ThemeMode.light;
  _Tahap _tahap = _Tahap.sambutan;

  // Kunci navigator dipegang di sini karena `context` milik state ini berada
  // DI ATAS MaterialApp — `Navigator.of(context)` dari sini tidak akan
  // menemukan navigator mana pun.
  final _kunciNavigator = GlobalKey<NavigatorState>();

  bool get _gelap => _mode == ThemeMode.dark;

  void _gantiTema() =>
      setState(() => _mode = _gelap ? ThemeMode.light : ThemeMode.dark);

  void _keTahap(_Tahap tahap) {
    // Alur pembuka menumpuk rutenya sendiri (sambutan → usaha → tujuan).
    // Tanpa membersihkan tumpukan itu, tombol kembali perangkat akan
    // memundurkan pengguna dari aplikasi ke layar pertanyaan.
    _kunciNavigator.currentState?.popUntil((r) => r.isFirst);
    setState(() => _tahap = tahap);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir POS',
      debugShowCheckedModeBanner: false,
      navigatorKey: _kunciNavigator,
      theme: TemaAplikasi.terang(),
      darkTheme: TemaAplikasi.gelap(),
      themeMode: _mode,
      home: switch (_tahap) {
        _Tahap.sambutan => SambutanScreen(
          onSelesai: () => _keTahap(_Tahap.masuk),
          onSudahPunyaAkun: () => _keTahap(_Tahap.masuk),
        ),
        _Tahap.masuk => LoginScreen(
          onMasuk: () => _keTahap(_Tahap.aplikasi),
          onKembali: () => _keTahap(_Tahap.sambutan),
        ),
        _Tahap.aplikasi => Beranda(
          onGantiTema: _gantiTema,
          gelap: _gelap,
          onKeluar: () => _keTahap(_Tahap.sambutan),
        ),
      },
    );
  }
}

/// Kerangka bertab. Terpisah dari [AplikasiPos] supaya perpindahan tab tidak
/// membangun ulang [MaterialApp] beserta seluruh temanya.
class Beranda extends StatefulWidget {
  const Beranda({
    super.key,
    required this.onGantiTema,
    required this.gelap,
    required this.onKeluar,
  });

  final VoidCallback onGantiTema;
  final bool gelap;
  final VoidCallback onKeluar;

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  int _indeks = 0;

  void _bukaKasir() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const KasirScreen(),
      ),
    );
  }

  void _keTab(int i) => setState(() => _indeks = i);

  @override
  Widget build(BuildContext context) {
    return AppShell(
      indeks: _indeks,
      onPindah: _keTab,
      anak: switch (_indeks) {
        0 => BerandaScreen(onBukaKasir: _bukaKasir, onKeTab: _keTab),
        1 => const ProdukScreen(),
        2 => const LaporanScreen(),
        3 => ResepScreen(onKeAkun: () => _keTab(4)),
        _ => AkunScreen(
          onGantiTema: widget.onGantiTema,
          gelap: widget.gelap,
          onKeluar: widget.onKeluar,
        ),
      },
    );
  }
}
