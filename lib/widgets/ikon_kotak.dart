import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum NadaIkon { netral, tinta, sukses, peringatan, bahaya, info }

/// Motif pengikat: ikon garis di dalam kotak lembut ber-radius.
///
/// Ini yang membuat halaman yang isinya berbeda-beda — daftar produk, baris
/// struk, menu akun — tetap terbaca satu keluarga. `design.md` § Motif
/// pengikat.
class IkonKotak extends StatelessWidget {
  const IkonKotak(
    this.ikon, {
    super.key,
    this.nada = NadaIkon.netral,
    this.ukuran = 40,
  });

  final IconData ikon;
  final NadaIkon nada;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final (latar, depan) = switch (nada) {
      NadaIkon.netral => (a.isian, context.warna.onSurfaceVariant),
      NadaIkon.tinta => (a.fokus, a.atasFokus),
      NadaIkon.sukses => (a.suksesLembut, a.sukses),
      NadaIkon.peringatan => (a.peringatanLembut, a.peringatan),
      NadaIkon.bahaya => (a.bahayaLembut, a.bahaya),
      NadaIkon.info => (a.infoLembut, a.info),
    };

    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(
          ukuran >= 40 ? Lengkung.kontrol : Lengkung.kecil,
        ),
      ),
      alignment: Alignment.center,
      // Ikon selalu 55% dari kotaknya. Ukuran ikon yang dipatok tetap membuat
      // kotak 32 px terlihat sesak dan kotak 52 px terlihat kosong.
      child: Icon(ikon, size: ukuran * 0.55, color: depan),
    );
  }
}
