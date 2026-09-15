import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'lencana.dart';

/// Penanda "Terpopuler" beserta jumlah buka sebuah konten.
///
/// Satu widget untuk kartu Pustaka dan kartu Klaim gratis: keduanya memuat
/// konten yang sama, dan lencana yang cuma muncul di salah satunya membuat
/// yang lain terasa seperti daftar kelas dua.
///
/// `Wrap`, bukan `Row`. Lencananya tidak bisa menyusut, dan pada layar 320 px
/// lebar kolom teks kartu Pustaka hanya ~150 px — lencana bersama angkanya
/// persis melewatinya. Dijatuhkan ke baris berikutnya jauh lebih baik daripada
/// dipotong, dan kartu Pustaka sudah diberi tinggi untuk menampungnya.
class PenandaPopuler extends StatelessWidget {
  const PenandaPopuler({
    super.key,
    required this.jumlahUnduhan,
    this.populer = false,
  });

  /// Berapa kali konten ini dibuka, menurut server.
  ///
  /// Angkanya menghitung BUKA, bukan unduh: endpoint yang sama dipakai
  /// aplikasi untuk membuka pratinjau. Labelnya karena itu "dibuka".
  final int jumlahUnduhan;

  /// Menyandang lencana "Terpopuler". Diputuskan pemanggil lewat
  /// `idTerpopuler`, bukan dihitung ulang di sini — supaya lencananya
  /// benar-benar sama di kedua layar.
  final bool populer;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Jarak.xs2,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (populer) const Lencana('Terpopuler', nada: NadaLencana.info),
        Text(
          '$jumlahUnduhan× dibuka',
          style: context.teks.labelSmall?.copyWith(
            color: context.warna.onSurfaceVariant,
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
