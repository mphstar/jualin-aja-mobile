import 'package:flutter/material.dart';

import '../data/model.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';

/// Grafik batang omzet harian — dibangun tangan dengan dukungan Interaktif/Hover/Tooltip.
class GrafikBatang extends StatefulWidget {
  const GrafikBatang({super.key, required this.titik, this.tinggi = 132});

  final List<TitikHarian> titik;
  final double tinggi;

  @override
  State<GrafikBatang> createState() => _GrafikBatangState();
}

class _GrafikBatangState extends State<GrafikBatang> {
  int? _terpilih;

  @override
  Widget build(BuildContext context) {
    if (widget.titik.isEmpty) return const SizedBox.shrink();

    final maks = widget.titik.fold(0, (n, t) => t.omzet > n ? t.omzet : n);
    final indeksMaks = widget.titik.indexWhere((t) => t.omzet == maks);
    final tertinggi = widget.titik[indeksMaks < 0 ? 0 : indeksMaks];

    final aktif = _terpilih != null &&
            _terpilih! >= 0 &&
            _terpilih! < widget.titik.length
        ? widget.titik[_terpilih!]
        : null;

    final adaLabel = widget.titik.length <= 12 ||
        widget.titik.any((t) => t.label != null && t.label!.isNotEmpty);

    final headerText = aktif != null
        ? '${aktif.label ?? tanggal(aktif.tanggal)}: ${rupiah(aktif.omzet)} (${aktif.transaksi} transaksi)'
        : '';

    final tertinggiText = tertinggi.label != null
        ? 'Tertinggi ${rupiah(tertinggi.omzet)} · ${tertinggi.label}'
        : 'Tertinggi ${rupiah(tertinggi.omzet)} · ${tanggal(tertinggi.tanggal)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 26,
          child: AnimatedCrossFade(
            crossFadeState: aktif != null
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: Gerak.cepat,
            alignment: Alignment.centerLeft,
            firstChild: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: context.aksen.fokus,
                borderRadius: BorderRadius.circular(Lengkung.kecil),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: context.aksen.atasFokus,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    headerText,
                    style: context.teks.bodySmall?.copyWith(
                      color: context.aksen.atasFokus,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            secondChild: maks > 0
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tertinggiText,
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: Jarak.xs),
        SizedBox(
          height: widget.tinggi,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.titik.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.titik.length > 12 ? 1 : 3,
                    ),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _terpilih = i),
                      onExit: (_) => setState(() => _terpilih = null),
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _terpilih = i),
                        child: Tooltip(
                          message:
                              '${widget.titik[i].label ?? tanggal(widget.titik[i].tanggal)}: ${rupiah(widget.titik[i].omzet)}',
                          child: _Batang(
                            porsi: maks == 0
                                ? 0.02
                                : (widget.titik[i].omzet / maks).clamp(
                                    0.02,
                                    1.0,
                                  ),
                            ditandai: i == indeksMaks && maks > 0,
                            terpilih: i == _terpilih,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.xs2),
        if (adaLabel)
          Row(
            children: [
              for (final t in widget.titik)
                Expanded(
                  child: Text(
                    t.label ?? hariPendek(t.tanggal),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: context.teks.labelSmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.titik.first.label ?? tanggal(widget.titik.first.tanggal),
                  style: context.teks.labelSmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  widget.titik.last.label ?? tanggal(widget.titik.last.tanggal),
                  textAlign: TextAlign.right,
                  style: context.teks.labelSmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Batang extends StatelessWidget {
  const _Batang({
    required this.porsi,
    required this.ditandai,
    this.terpilih = false,
  });

  final double porsi;
  final bool ditandai;
  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: porsi,
        widthFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            color: terpilih
                ? context.aksen.peringatan
                : ditandai
                    ? context.aksen.fokus
                    : context.aksen.isian,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Jarak.xs3),
            ),
            border: terpilih
                ? Border.all(color: context.warna.onSurface, width: 1.5)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Sparkline mikro untuk tren omzet di beranda.
class Percikan extends StatelessWidget {
  const Percikan({
    super.key,
    required this.nilai,
    required this.warna,
    this.warnaAkhir,
    this.tinggi = 28,
  });

  final List<int> nilai;
  final Color warna;
  final Color? warnaAkhir;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    if (nilai.isEmpty) return SizedBox(height: tinggi);

    final maks = nilai.fold(0, (n, v) => v > n ? v : n);

    return SizedBox(
      height: tinggi,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < nilai.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: maks == 0
                        ? 0.05
                        : (nilai[i] / maks).clamp(0.05, 1.0),
                    widthFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: i == nilai.length - 1 && warnaAkhir != null
                            ? warnaAkhir
                            : warna,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bilah porsi horizontal untuk daftar produk terlaris.
class BilahPorsi extends StatelessWidget {
  const BilahPorsi({
    super.key,
    required this.porsi,
    required this.ditandai,
    this.tinggi = 6,
  });

  final double porsi;
  final bool ditandai;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tinggi,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.aksen.isian,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: porsi.clamp(0.02, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: ditandai ? context.aksen.fokus : context.warna.outline,
            borderRadius: BorderRadius.circular(Lengkung.bulat),
          ),
        ),
      ),
    );
  }
}
