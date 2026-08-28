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
      label: 'Pustaka',
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
        bottomNavigationBar: _BilahBawah(indeks: indeks, onPindah: onPindah),
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
      child: TandaMerekBackdoor(ukuran: 40, berlabel: melebar),
    );
  }
}

// ---------------------------------------------------------------------------
// Bilah navigasi bawah (ponsel) — mengambang, item aktif berkapsul tinta
// ---------------------------------------------------------------------------

class _BilahBawah extends StatelessWidget {
  const _BilahBawah({required this.indeks, required this.onPindah});

  final int indeks;
  final ValueChanged<int> onPindah;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Lengkung.panel),
        ),
        boxShadow: [
          BoxShadow(
            color: context.warna.outline.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < AppShell.tujuan.length; i++)
                Expanded(
                  child: _ItemBilah(
                    aktif: i == indeks,
                    tujuan: AppShell.tujuan[i],
                    onTekan: () => onPindah(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemBilah extends StatelessWidget {
  const _ItemBilah({
    required this.aktif,
    required this.tujuan,
    required this.onTekan,
  });

  final bool aktif;
  final TujuanNav tujuan;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final warna =
        aktif ? a.fokus : context.warna.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: aktif,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aktif ? tujuan.ikonAktif : tujuan.ikon,
                size: 22,
                color: warna,
              ),
              const SizedBox(height: 4),
              Text(
                tujuan.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.teks.labelSmall?.copyWith(
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                  color: warna,
                ),
              ),
            ],
          ),
        ),
      ),
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
