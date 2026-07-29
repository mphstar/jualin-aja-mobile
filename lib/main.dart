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

import 'data/repositori.dart';
import 'screens/akun_screen.dart';
import 'screens/beranda_screen.dart';
import 'screens/daftar_screen.dart';
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

/// Lima tahap: memuat (cek token) → sambutan → masuk → daftar → aplikasi.
enum _Tahap { memuat, sambutan, masuk, daftar, aplikasi }

class _AplikasiPosState extends State<AplikasiPos> {
  ThemeMode _mode = ThemeMode.light;
  _Tahap _tahap = _Tahap.memuat;

  final _kunciNavigator = GlobalKey<NavigatorState>();

  bool get _gelap => _mode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _cekSesi();
  }

  /// Periksa apakah ada token tersimpan yang masih sah.
  Future<void> _cekSesi() async {
    final sesi = await Repositori.cekSesi();
    if (!mounted) return;
    setState(() => _tahap = sesi != null ? _Tahap.aplikasi : _Tahap.sambutan);
  }

  void _gantiTema() =>
      setState(() => _mode = _gelap ? ThemeMode.light : ThemeMode.dark);

  void _keTahap(_Tahap tahap) {
    _kunciNavigator.currentState?.popUntil((r) => r.isFirst);
    setState(() => _tahap = tahap);
  }

  Future<void> _keluar() async {
    await Repositori.keluar();
    if (!mounted) return;
    _keTahap(_Tahap.sambutan);
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
        _Tahap.memuat => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        _Tahap.sambutan => SambutanScreen(
          onSelesai: () => _keTahap(_Tahap.daftar),
          onSudahPunyaAkun: () => _keTahap(_Tahap.masuk),
        ),
        _Tahap.masuk => LoginScreen(
          onMasuk: () => _keTahap(_Tahap.aplikasi),
          onKembali: () => _keTahap(_Tahap.sambutan),
          onDaftar: () => _keTahap(_Tahap.daftar),
        ),
        _Tahap.daftar => DaftarScreen(
          onBerhasilDaftar: () => _keTahap(_Tahap.aplikasi),
          onMasuk: () => _keTahap(_Tahap.masuk),
        ),
        _Tahap.aplikasi => Beranda(
          onGantiTema: _gantiTema,
          gelap: _gelap,
          onKeluar: _keluar,
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
