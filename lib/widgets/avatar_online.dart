import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../util/avatar.dart';

/// Avatar online dari nama (bukan inisial). Kalau gambar gagal dimuat atau
/// belum siap, tampil siluet orang — bukan inisial yang membosankan.
class AvatarOnline extends StatelessWidget {
  const AvatarOnline({
    super.key,
    required this.nama,
    this.perempuan,
    this.ukuran = 44,
  });

  final String nama;
  final bool? perempuan;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        avatarUrl(nama.isEmpty ? 'Pengguna' : nama, perempuan: perempuan),
        width: ukuran,
        height: ukuran,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _siluet(context),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _siluet(context),
      ),
    );
  }

  Widget _siluet(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: context.aksen.isian,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: ukuran * 0.55,
        color: context.warna.onSurfaceVariant,
      ),
    );
  }
}
