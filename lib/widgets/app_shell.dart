import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'peraga.dart';

/// Kerangka navigasi.
///
/// Tiga bentuk, bukan dua:
///
/// | Lebar | Bentuk |
/// |---|---|
/// | < 600 | bilah bawah |
/// | 600–999 | rail ikon di kiri |
/// | ≥ 1000 | rail melebar berlabel |
///
/// Tablet yang dipaksa memakai bentuk ponsel membuang setengah layarnya; yang
/// dipaksa memakai bentuk desktop kehilangan setengah layar untuk rail.
///
/// **Kasir sengaja tidak ada di sini.** Ia mode, bukan tujuan — dibuka layar
/// penuh dari Beranda dan ditutup kembali. Menaruhnya sebagai tab keenam akan
/// membuat pengguna bisa berpindah keluar di tengah transaksi hanya dengan
/// salah sentuh.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.indeks,
    required this.onPindah,
    required this.anak,
  });

  final int indeks;
  final ValueChanged<int> onPindah;
  final Widget anak;

  static const tujuan = <TujuanNav>[
    TujuanNav(
      label: 'Beranda',
      ikon: Icons.home_outlined,
      ikonAktif: Icons.home,
    ),
    TujuanNav(
      label: 'Produk',
      ikon: Icons.inventory_2_outlined,
      ikonAktif: Icons.inventory_2,
    ),
    TujuanNav(
      label: 'Laporan',
      ikon: Icons.bar_chart_outlined,
      ikonAktif: Icons.bar_chart,
    ),
    TujuanNav(
      label: 'Resep',
      ikon: Icons.menu_book_outlined,
      ikonAktif: Icons.menu_book,
    ),
    TujuanNav(
      label: 'Akun',
      ikon: Icons.person_outline,
      ikonAktif: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;

    if (lebar < Ambang.ringkas) {
      return Scaffold(
        body: SafeArea(bottom: false, child: anak),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.warna.outline)),
          ),
          child: NavigationBar(
            selectedIndex: indeks,
            onDestinationSelected: onPindah,
            destinations: [
              for (final t in tujuan)
                NavigationDestination(
                  icon: Icon(t.ikon),
                  selectedIcon: Icon(t.ikonAktif),
                  label: t.label,
                ),
            ],
          ),
        ),
      );
    }

    final melebar = lebar >= Ambang.luas;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: indeks,
              onDestinationSelected: onPindah,
              extended: melebar,
              labelType: melebar
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              minExtendedWidth: 208,
              leading: _MerekRail(melebar: melebar),
              destinations: [
                for (final t in tujuan)
                  NavigationRailDestination(
                    icon: Icon(t.ikon),
                    selectedIcon: Icon(t.ikonAktif),
                    label: Text(t.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: context.warna.outline),
            // min-width nol wajib: tanpa ini isi yang lebar akan mendorong
            // rail keluar layar alih-alih menggulir di dalam ruangnya sendiri.
            Expanded(child: ClipRect(child: anak)),
          ],
        ),
      ),
    );
  }
}

class TujuanNav {
  const TujuanNav({
    required this.label,
    required this.ikon,
    required this.ikonAktif,
  });

  final String label;
  final IconData ikon;
  final IconData ikonAktif;
}

class _MerekRail extends StatelessWidget {
  const _MerekRail({required this.melebar});

  final bool melebar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        melebar ? Jarak.sm : 0,
        Jarak.sm,
        melebar ? Jarak.sm : 0,
        Jarak.md,
      ),
      child: TandaMerek(ukuran: 40, berlabel: melebar),
    );
  }
}

/// Padding halaman yang melebar bertahap. Angkanya sama untuk semua layar,
/// jadi tepi kiri kartu di Beranda persis sejajar dengan tepi kiri kartu di
/// Laporan — hal kecil yang langsung terasa salah kalau meleset dua piksel.
EdgeInsets paddingHalaman(BuildContext context) {
  final lebar = MediaQuery.sizeOf(context).width;
  final sisi = lebar >= Ambang.luas
      ? Jarak.lg
      : lebar >= Ambang.ringkas
      ? Jarak.md
      : Jarak.sm;
  return EdgeInsets.fromLTRB(sisi, Jarak.sm, sisi, Jarak.lg);
}
