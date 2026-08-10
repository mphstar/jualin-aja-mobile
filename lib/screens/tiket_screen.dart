import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/bingkai.dart';
import '../widgets/ikon_kotak.dart';
import '../widgets/rangka.dart';
import 'detail_tiket_screen.dart';
import 'form_tiket_screen.dart';

/// Halaman Riwayat Tiket Saran & Komplain Pengguna Mobile.
class TiketScreen extends StatelessWidget {
  const TiketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saran & Komplain'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final dibuat = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const FormTiketScreen(),
            ),
          );
          if (dibuat == true && context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Laporan/Saran berhasil dikirim ke tim admin.'),
                ),
              );
          }
        },
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Kirim Laporan'),
      ),
      body: SafeArea(
        top: false,
        child: Bingkai<List<TiketDukungan>>(
          ambil: Repositori.tiket,
          rangka: const Padding(
            padding: EdgeInsets.all(Jarak.md),
            child: RangkaDaftar(baris: 4),
          ),
          kosong: (daftar) => daftar.isEmpty,
          saatKosong: const Center(
            child: Padding(
              padding: EdgeInsets.all(Jarak.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IkonKotak(Icons.mark_chat_read_outlined, ukuran: 56),
                  SizedBox(height: Jarak.sm),
                  Text(
                    'Belum Ada Laporan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: Jarak.xs2),
                  Text(
                    'Punya saran fitur atau menemukan kendala? Kirim pesan ke tim kami lewat tombol di bawah.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          isi: (context, daftar) {
            return RefreshIndicator(
              onRefresh: () async => revisiData.value++,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Jarak.md,
                  Jarak.md,
                  Jarak.md,
                  80,
                ),
                itemCount: daftar.length,
                separatorBuilder: (_, _) => const SizedBox(height: Jarak.sm),
                itemBuilder: (context, index) {
                  final t = daftar[index];
                  return _KartuTiket(tiket: t);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KartuTiket extends StatelessWidget {
  const _KartuTiket({required this.tiket});

  final TiketDukungan tiket;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (tiket.status) {
      StatusTiketTiketing.terbuka => context.warna.error,
      StatusTiketTiketing.diproses => context.warna.primary,
      StatusTiketTiketing.selesai => const Color(0xFF10B981),
      StatusTiketTiketing.ditutup => context.warna.onSurfaceVariant,
    };

    return Material(
      color: context.warna.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Lengkung.kontrol),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          border: Border.all(color: context.warna.outlineVariant),
        ),
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Jarak.md,
          vertical: Jarak.xs2,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailTiketScreen(tiketId: tiket.id),
            ),
          );
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tiket.status.label,
                style: context.teks.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: Jarak.xs2),
            Expanded(
              child: Text(
                tiket.nomorTiket,
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Jarak.xs3),
            Text(
              tiket.subjek,
              style: context.teks.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Jarak.xs3),
            Text(
              tiket.jenis.label,
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
            ),
            if (tiket.balasanAdmin != null) ...[
              const SizedBox(height: Jarak.xs2),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Color(0xFF047857),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sudah Dibalas Admin',
                    style: context.teks.labelSmall?.copyWith(
                      color: const Color(0xFF047857),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: context.warna.onSurfaceVariant,
        ),
      ),
    ),
  );
}
}
