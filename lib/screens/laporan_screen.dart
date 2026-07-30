import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/app_shell.dart';
import '../widgets/batang.dart';
import '../widgets/bingkai.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/rangka.dart';
import 'riwayat_screen.dart';

/// Laporan penjualan (PRD §1 · §13 — "laporan").
///
/// Dua tab, karena ini satu data pada dua tingkat perbesaran: **Ringkasan**
/// menjawab "bagaimana minggu ini", **Riwayat** menjawab "mana struk yang
/// tadi". Menjadikan keduanya dua tujuan navigasi terpisah memaksa pengguna
/// memutuskan lebih dulu pertanyaan mana yang sedang ia punya — dan itu
/// keputusan yang tidak perlu.
///
/// **Tidak ada satu angka pun yang dikarang di layar ini.** Semuanya
/// diturunkan dari transaksi di [Repositori.laporan]. Laporan dengan angka
/// hiasan tidak pernah ketahuan salah sampai dipakai sungguhan.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            0,
          ),
          child: const KepalaHalaman(judul: 'Laporan'),
        ),
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Riwayat'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _Ringkasan(padding: padding),
              RiwayatScreen(padding: padding),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Ringkasan
// ---------------------------------------------------------------------------

class _Ringkasan extends StatefulWidget {
  const _Ringkasan({required this.padding});

  final EdgeInsets padding;

  @override
  State<_Ringkasan> createState() => _RingkasanState();
}

class _RingkasanState extends State<_Ringkasan> {
  String _modeFilter = 'TUJUH_HARI';
  DateTime? _tanggalRef;
  DateTimeRange? _customRange;

  Future<void> _pilihTanggalHarian() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _tanggalRef ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      confirmText: 'Pilih Hari',
    );
    if (tgl != null) {
      final start = DateTime(tgl.year, tgl.month, tgl.day, 0, 0, 0);
      final end = DateTime(tgl.year, tgl.month, tgl.day, 23, 59, 59);
      setState(() {
        _tanggalRef = tgl;
        _customRange = DateTimeRange(start: start, end: end);
        _modeFilter = 'HARI_INI';
      });
    }
  }

  Future<void> _pilihMingguan() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _tanggalRef ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      confirmText: 'Pilih Minggu',
    );
    if (tgl != null) {
      final end = DateTime(tgl.year, tgl.month, tgl.day, 23, 59, 59);
      final start = DateTime(tgl.year, tgl.month, tgl.day).subtract(const Duration(days: 6));
      setState(() {
        _tanggalRef = tgl;
        _customRange = DateTimeRange(start: start, end: end);
        _modeFilter = 'TUJUH_HARI';
      });
    }
  }

  Future<void> _pilihBulanan() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _tanggalRef ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDatePickerMode: DatePickerMode.year,
      confirmText: 'Pilih Bulan',
    );
    if (tgl != null) {
      final start = DateTime(tgl.year, tgl.month, 1);
      final end = DateTime(tgl.year, tgl.month + 1, 0, 23, 59, 59);
      setState(() {
        _tanggalRef = tgl;
        _customRange = DateTimeRange(start: start, end: end);
        _modeFilter = 'TIGA_PULUH_HARI';
      });
    }
  }

  Future<void> _pilihTahunan() async {
    final tahunKini = DateTime.now().year;
    final terpilih = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Tahun Laporan'),
          content: SizedBox(
            width: 250,
            height: 250,
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                final thn = tahunKini - index;
                return ListTile(
                  title: Text('Tahun $thn', textAlign: TextAlign.center),
                  onTap: () => Navigator.pop(context, thn),
                );
              },
            ),
          ),
        );
      },
    );
    if (terpilih != null) {
      final start = DateTime(terpilih, 1, 1);
      final end = DateTime(terpilih, 12, 31, 23, 59, 59);
      setState(() {
        _tanggalRef = start;
        _customRange = DateTimeRange(start: start, end: end);
        _modeFilter = 'TAHUNAN';
      });
    }
  }

  Future<void> _pilihCustomRange() async {
    final awal = _customRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: awal,
      confirmText: 'Pilih',
    );
    if (hasil != null) {
      setState(() {
        _customRange = hasil;
        _modeFilter = 'CUSTOM';
      });
    }
  }

  void _onPilihMode(String mode) {
    if (mode == _modeFilter && _customRange != null) {
      _bukaPickerMode(mode);
      return;
    }

    switch (mode) {
      case 'HARI_INI':
        setState(() {
          _modeFilter = 'HARI_INI';
          _tanggalRef = DateTime.now();
          _customRange = null;
        });
        break;
      case 'TUJUH_HARI':
        setState(() {
          _modeFilter = 'TUJUH_HARI';
          _customRange = null;
        });
        break;
      case 'TIGA_PULUH_HARI':
        setState(() {
          _modeFilter = 'TIGA_PULUH_HARI';
          _customRange = null;
        });
        break;
      case 'TAHUNAN':
        setState(() {
          _modeFilter = 'TAHUNAN';
          _customRange = null;
        });
        break;
      case 'CUSTOM':
        _pilihCustomRange();
        break;
    }
  }

  void _bukaPickerMode(String mode) {
    switch (mode) {
      case 'HARI_INI':
        _pilihTanggalHarian();
        break;
      case 'TUJUH_HARI':
        _pilihMingguan();
        break;
      case 'TIGA_PULUH_HARI':
        _pilihBulanan();
        break;
      case 'TAHUNAN':
        _pilihTahunan();
        break;
      case 'CUSTOM':
        _pilihCustomRange();
        break;
    }
  }

  String get _labelRincianPeriode {
    if (_customRange != null) {
      if (_modeFilter == 'HARI_INI') {
        return 'Hari: ${tanggal(_customRange!.start)}';
      }
      if (_modeFilter == 'TUJUH_HARI') {
        return 'Minggu: ${tanggal(_customRange!.start)} - ${tanggal(_customRange!.end)}';
      }
      if (_modeFilter == 'TIGA_PULUH_HARI') {
        return 'Bulan: ${tanggal(_customRange!.start)} - ${tanggal(_customRange!.end)}';
      }
      if (_modeFilter == 'TAHUNAN') {
        return 'Tahun: ${_customRange!.start.year}';
      }
      return 'Rentang: ${tanggal(_customRange!.start)} - ${tanggal(_customRange!.end)}';
    }
    return switch (_modeFilter) {
      'HARI_INI' => 'Hari Ini (${tanggal(DateTime.now())})',
      'TUJUH_HARI' => '7 Hari Terakhir',
      'TIGA_PULUH_HARI' => '30 Hari Terakhir',
      'TAHUNAN' => '1 Tahun Terakhir (${DateTime.now().year})',
      _ => 'Rentang Kustom',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.padding;
    final kunci =
        '$_modeFilter|${_customRange?.start.toIso8601String()}|${_customRange?.end.toIso8601String()}';

    return ListView(
      padding: EdgeInsets.fromLTRB(p.left, Jarak.sm, p.right, p.bottom),
      children: [
        _PilihPeriodeLengkap(
          modeFilter: _modeFilter,
          labelPeriode: _labelRincianPeriode,
          onPilihMode: _onPilihMode,
          onKlikRincian: () => _bukaPickerMode(_modeFilter),
        ),
        const SizedBox(height: Jarak.sm),
        Bingkai<Laporan>(
          key: ValueKey(kunci),
          ambil: () => Repositori.laporan(
            modeFilter: _modeFilter,
            customRange: _customRange,
          ),
          rangka: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              RangkaPanel(tinggi: 150),
              SizedBox(height: Jarak.md),
              RangkaPanel(tinggi: 210),
              SizedBox(height: Jarak.md),
              RangkaDaftar(baris: 4),
            ],
          ),
          kosong: (l) => l.kosong,
          saatKosong: const Keadaan(
            ikon: Icons.bar_chart_outlined,
            judul: 'Belum ada penjualan',
            keterangan:
                'Tidak ada transaksi selesai dalam periode terpilih. '
                'Laporan akan terisi sendiri begitu kasir dipakai.',
          ),
          isi: (context, l) => _IsiRingkasan(laporan: l),
        ),
      ],
    );
  }
}

class _PilihPeriodeLengkap extends StatelessWidget {
  const _PilihPeriodeLengkap({
    required this.modeFilter,
    required this.labelPeriode,
    required this.onPilihMode,
    required this.onKlikRincian,
  });

  final String modeFilter;
  final String labelPeriode;
  final ValueChanged<String> onPilihMode;
  final VoidCallback onKlikRincian;

  @override
  Widget build(BuildContext context) {
    final pilihan = [
      ('HARI_INI', 'Harian'),
      ('TUJUH_HARI', 'Mingguan'),
      ('TIGA_PULUH_HARI', 'Bulanan'),
      ('TAHUNAN', 'Tahunan'),
      ('CUSTOM', 'Kustom'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (mode, label) in pilihan) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: modeFilter == mode,
                    onSelected: (selected) {
                      if (selected) onPilihMode(mode);
                    },
                    selectedColor: context.aksen.fokus,
                    labelStyle: TextStyle(
                      color: modeFilter == mode
                          ? context.aksen.atasFokus
                          : context.warna.onSurface,
                      fontWeight:
                          modeFilter == mode ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onKlikRincian,
          borderRadius: BorderRadius.circular(Lengkung.kecil),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.aksen.isian,
              borderRadius: BorderRadius.circular(Lengkung.kecil),
              border: Border.all(color: context.warna.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: context.warna.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  labelPeriode,
                  style: context.teks.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.warna.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: context.warna.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IsiRingkasan extends StatelessWidget {
  const _IsiRingkasan({required this.laporan});

  final Laporan laporan;

  @override
  Widget build(BuildContext context) {
    final duaKolom = MediaQuery.sizeOf(context).width >= 900;

    final kiri = <Widget>[
      _PanelOmzet(laporan: laporan),
      const SizedBox(height: Jarak.md),
      _KartuGrafik(laporan: laporan),
    ];

    final kanan = <Widget>[
      _Terlaris(daftar: laporan.terlaris),
      const SizedBox(height: Jarak.md),
      _Metode(daftar: laporan.metode, omzet: laporan.omzet),
    ];

    if (!duaKolom) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...kiri,
          const SizedBox(height: Jarak.md),
          ...kanan,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: kiri,
          ),
        ),
        const SizedBox(width: Jarak.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: kanan,
          ),
        ),
      ],
    );
  }
}

class _PanelOmzet extends StatelessWidget {
  const _PanelOmzet({required this.laporan});

  final Laporan laporan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: a.fokus,
        borderRadius: BorderRadius.circular(Lengkung.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Omzet ${laporan.periode.label.toLowerCase()}',
            style: context.teks.bodyMedium?.copyWith(color: a.atasFokusRedup),
          ),
          const SizedBox(height: Jarak.xs2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(laporan.omzet),
              style: context.teks.displaySmall?.copyWith(
                color: a.atasFokus,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: Jarak.sm),
          Row(
            children: [
              Expanded(
                child: _AngkaGelap(
                  label: 'Transaksi',
                  nilai: '${laporan.transaksi}',
                ),
              ),
              _PemisahGelap(),
              Expanded(
                child: _AngkaGelap(label: 'Item', nilai: '${laporan.item}'),
              ),
              _PemisahGelap(),
              Expanded(
                child: _AngkaGelap(
                  label: 'Rata/struk',
                  nilai: ringkasRupiah(laporan.rataPerStruk),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PemisahGelap extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: Jarak.xs2),
    color: context.aksen.atasFokusRedup.withValues(alpha: 0.3),
  );
}

class _AngkaGelap extends StatelessWidget {
  const _AngkaGelap({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            nilai,
            style: context.teks.titleMedium?.copyWith(
              color: context.aksen.atasFokus,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(
          label,
          style: context.teks.bodySmall?.copyWith(
            color: context.aksen.atasFokusRedup,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _KartuGrafik extends StatelessWidget {
  const _KartuGrafik({required this.laporan});

  final Laporan laporan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JudulBagian('Omzet harian'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Jarak.sm),
            child: GrafikBatang(titik: laporan.harian),
          ),
        ),
      ],
    );
  }
}

class _Terlaris extends StatelessWidget {
  const _Terlaris({required this.daftar});

  final List<ProdukTerlaris> daftar;

  @override
  Widget build(BuildContext context) {
    if (daftar.isEmpty) return const SizedBox.shrink();
    final tertinggi = daftar.first.jumlah;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JudulBagian('Produk terlaris'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Jarak.sm),
            child: Column(
              children: [
                for (var i = 0; i < daftar.length; i++) ...[
                  if (i > 0) const SizedBox(height: Jarak.xs),
                  _BarisTerlaris(
                    peringkat: i + 1,
                    item: daftar[i],
                    porsi: tertinggi == 0 ? 0 : daftar[i].jumlah / tertinggi,
                    ditandai: i == 0,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BarisTerlaris extends StatelessWidget {
  const _BarisTerlaris({
    required this.peringkat,
    required this.item,
    required this.porsi,
    required this.ditandai,
  });

  final int peringkat;
  final ProdukTerlaris item;
  final double porsi;
  final bool ditandai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$peringkat',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                item.nama,
                style: context.teks.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Jarak.xs2),
            Text(
              '${item.jumlah}',
              style: context.teks.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: BilahPorsi(porsi: porsi, ditandai: ditandai),
        ),
      ],
    );
  }
}

class _Metode extends StatelessWidget {
  const _Metode({required this.daftar, required this.omzet});

  final List<PorsiMetode> daftar;
  final int omzet;

  @override
  Widget build(BuildContext context) {
    if (daftar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JudulBagian('Metode pembayaran'),
        KartuDaftar(
          anak: [
            for (final m in daftar)
              BarisDaftar(
                awalan: Icon(
                  switch (m.metode) {
                    MetodeBayar.tunai => Icons.payments_outlined,
                    MetodeBayar.qris => Icons.qr_code_2,
                    MetodeBayar.transfer => Icons.account_balance_outlined,
                  },
                  size: 22,
                  color: context.warna.onSurfaceVariant,
                ),
                judul: m.metode.label,
                keterangan:
                    '${m.transaksi} transaksi · '
                    '${omzet == 0 ? 0 : (m.omzet * 100 / omzet).round()}%',
                akhiran: rupiah(m.omzet),
              ),
          ],
        ),
      ],
    );
  }
}
