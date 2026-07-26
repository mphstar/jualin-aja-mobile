import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Tombol pil selebar layar — bentuk baku untuk aksi tunggal di alur pembuka
/// dan layar masuk.
///
/// Ia memakai `primary` bawaan tema, yang di sistem ini adalah tinta. Tidak
/// ada warna yang ditulis di sini sama sekali; yang berbeda dari `FilledButton`
/// biasa cuma bentuknya (stadium) dan tingginya.
class TombolPil extends StatelessWidget {
  const TombolPil({
    super.key,
    required this.label,
    required this.onTekan,
    this.memproses = false,
  });

  final String label;

  /// Null berarti nonaktif — dipakai saat pilihan wajib belum diisi.
  final VoidCallback? onTekan;
  final bool memproses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: memproses ? null : onTekan,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: memproses
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.warna.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Titik penanda halaman untuk carousel pembuka.
class TitikHalaman extends StatelessWidget {
  const TitikHalaman({super.key, required this.jumlah, required this.aktif});

  final int jumlah;
  final int aktif;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < jumlah; i++)
          AnimatedContainer(
            duration: Gerak.sedang,
            curve: Gerak.keluar,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            // Titik aktif memanjang, bukan sekadar menggelap: bentuk terbaca
            // lebih cepat daripada beda kepekatan pada objek sekecil ini.
            width: i == aktif ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == aktif
                  ? context.warna.onSurface
                  : context.warna.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Lengkung.bulat),
            ),
          ),
      ],
    );
  }
}
