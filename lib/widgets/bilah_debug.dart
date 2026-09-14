import 'package:flutter/material.dart';

import '../data/backdoor.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Bilah penanda mode debug, dipasang di `MaterialApp.builder` supaya selalu
/// tampil di atas layar mana pun dan tetap bisa memakai `context.warna`.
///
/// Bilahnya **melayang** di atas aplikasi, bukan menumpuk tinggi bersamanya.
/// `Stack` dengan [StackFit.passthrough] meneruskan batasan induknya apa
/// adanya, jadi `Navigator` menerima batasan yang persis sama seperti kalau
/// pembungkus ini tidak ada — layar penuh, dua-duanya ketat. Bentuk pohonnya
/// juga tidak pernah berubah, dan bilahnya disembunyikan dengan [Offstage]
/// alih-alih dibuang dari pohon.
///
/// Bentuk lama menaruh `Column(Offstage, Expanded)` sebagai induk `Navigator`.
/// Dua hal meleset sekaligus: menyalakan mode debug memangkas tinggi yang
/// tersedia sementara `MediaQuery` yang dilihat isi aplikasi tetap mengaku
/// setinggi layar, dan `Expanded` di posisi itu membuat cabang isi aplikasi
/// tidak ikut dilayout padahal tetap digambar — Flutter membalasnya dengan
/// `RenderBox was not laid out`, menyebut widget `Expanded` di berkas ini,
/// disusul assertion `!semantics.parentDataDirty`.
class BilahDebug extends StatelessWidget {
  const BilahDebug({super.key, required this.anak});

  final Widget anak;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: modeDebug,
      builder: (context, debug, _) => Stack(
        fit: StackFit.passthrough,
        children: [
          anak,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Penanda visual, bukan kontrol. Tanpa ini ia menelan sentuhan
            // yang sebenarnya ditujukan ke isi aplikasi di bawahnya.
            child: IgnorePointer(
              child: Offstage(offstage: !debug, child: const _Bilah()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bilah extends StatelessWidget {
  const _Bilah();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.warna.error,
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: Jarak.xs),
      child: Text(
        'MODE DEBUG · BACKDOOR',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.warna.onError,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
