import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../data/sesi_kasir.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../util/pencetak_struk.dart';
import 'bingkai.dart';
import 'ikon_kotak.dart';
import 'kartu.dart';
import 'lembar_struk.dart';
import 'rangka.dart';

/// Modal lembar bawah untuk melihat Riwayat Shift Kasir.
class LembarRiwayatShift extends StatelessWidget {
  const LembarRiwayatShift({super.key});

  static Future<void> tampilkan(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const LembarRiwayatShift(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tinggiMaks = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: tinggiMaks),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 24,
                    color: context.warna.onSurface,
                  ),
                  const SizedBox(width: Jarak.xs2),
                  Expanded(
                    child: Text(
                      'Riwayat Shift Kasir',
                      style: context.teks.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Ketuk salah satu shift untuk melihat rincian transaksi sesi tersebut.',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Jarak.sm),

              Flexible(
                child: Bingkai<List<SesiKasir>>(
                  ambil: Repositori.riwayatSesiKasir,
                  rangka: const Padding(
                    padding: EdgeInsets.all(Jarak.xs),
                    child: Column(
                      children: [
                        RangkaPanel(tinggi: 120),
                        SizedBox(height: Jarak.sm),
                        RangkaPanel(tinggi: 120),
                      ],
                    ),
                  ),
                  kosong: (data) => data.isEmpty,
                  saatKosong: const Padding(
                    padding: EdgeInsets.all(Jarak.md),
                    child: Center(
                      child: Text('Belum ada riwayat shift kasir yang ditutup.'),
                    ),
                  ),
                  isi: (context, data) {
                    final perHari = <DateTime, List<SesiKasir>>{};
                    for (final s in data) {
                      final hari = DateTime(
                        s.waktuBuka.year,
                        s.waktuBuka.month,
                        s.waktuBuka.day,
                      );
                      perHari.putIfAbsent(hari, () => []).add(s);
                    }

                    final kini = DateTime.now();
                    final hariIni = DateTime(kini.year, kini.month, kini.day);

                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry in perHari.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: Jarak.xs,
                              bottom: Jarak.xs2,
                            ),
                            child: Text(
                              entry.key == hariIni
                                  ? 'Hari ini'
                                  : entry.key ==
                                          hariIni.subtract(
                                            const Duration(days: 1),
                                          )
                                      ? 'Kemarin'
                                      : tanggal(entry.key),
                              style: context.teks.labelMedium?.copyWith(
                                color: context.warna.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          KartuDaftar(
                            anak: [
                              for (final s in entry.value)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => LembarRincianShift.tampilkan(
                                      context,
                                      s,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(Jarak.xs),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.person_outline,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    s.namaKasir,
                                                    style: context
                                                        .teks
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${s.jumlahTransaksi} transaksi',
                                                    style: context
                                                        .teks
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: context
                                                              .warna
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.chevron_right,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Buka: ${jam(s.waktuBuka)} '
                                            '${s.waktuTutup != null ? "· Tutup: ${jam(s.waktuTutup!)}" : "(Shift Berjalan)"}',
                                            style: context.teks.bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .warna
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const Divider(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Kas Awal: ${rupiah(s.totalKasAwal)}',
                                                style: context.teks.bodySmall,
                                              ),
                                              Text(
                                                'Omzet: ${rupiah(s.totalPenjualan)}',
                                                style: context.teks.bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Setoran Fisik: ${rupiah(s.totalKasFisik)}',
                                                style: context.teks.bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              Text(
                                                s.totalSelisih == 0
                                                    ? 'Selisih: Pas'
                                                    : 'Selisih: ${rupiah(s.totalSelisih)}',
                                                style: context.teks.bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: s.totalSelisih == 0
                                                          ? context.aksen.sukses
                                                          : s.totalSelisih < 0
                                                          ? context
                                                              .aksen
                                                              .bahaya
                                                          : context
                                                              .aksen
                                                              .peringatan,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          if (s.catatan != null &&
                                              s.catatan!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Catatan: ${s.catatan}',
                                              style: context.teks.bodySmall
                                                  ?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                    color: context
                                                        .warna
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: Jarak.xs),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal rincian shift beserta daftar transaksi khusus pada sesi tersebut.
class LembarRincianShift extends StatelessWidget {
  const LembarRincianShift({super.key, required this.sesi});

  final SesiKasir sesi;

  static Future<void> tampilkan(BuildContext context, SesiKasir sesi) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => LembarRincianShift(sesi: sesi),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tinggiMaks = MediaQuery.sizeOf(context).height * 0.9;
    final totalSelisih = sesi.totalSelisih;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: tinggiMaks),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 24,
                    color: context.warna.onSurface,
                  ),
                  const SizedBox(width: Jarak.xs2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Shift: ${sesi.namaKasir}',
                          style: context.teks.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Buka: ${tanggal(sesi.waktuBuka)} ${jam(sesi.waktuBuka)} '
                          '${sesi.waktuTutup != null ? "· Tutup: ${jam(sesi.waktuTutup!)}" : "(Shift Berjalan)"}',
                          style: context.teks.bodySmall?.copyWith(
                            color: context.warna.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Cetak Laporan Bluetooth',
                    onPressed: () async {
                      try {
                        final toko = await Repositori.toko();
                        final pengaturan = await Repositori.pengaturanStruk();
                        if (!context.mounted) return;
                        await PencetakStruk.cetakLaporanShiftBluetooth(
                          context,
                          toko: toko,
                          pengaturan: pengaturan,
                          sesi: sesi,
                        );
                      } catch (_) {}
                    },
                  ),
                ],
              ),
              const SizedBox(height: Jarak.xs),

              // Rangkuman Shift Card
              Container(
                padding: const EdgeInsets.all(Jarak.xs),
                decoration: BoxDecoration(
                  color: context.warna.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(Lengkung.kontrol),
                  border: Border.all(color: context.warna.outline),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Modal Kas Awal: ${rupiah(sesi.totalKasAwal)}',
                          style: context.teks.bodySmall,
                        ),
                        Text(
                          'Total Omzet: ${rupiah(sesi.totalPenjualan)}',
                          style: context.teks.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kas Fisik: ${rupiah(sesi.totalKasFisik)}',
                          style: context.teks.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalSelisih == 0
                              ? 'Selisih: Pas'
                              : 'Selisih: ${rupiah(totalSelisih)}',
                          style: context.teks.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: totalSelisih == 0
                                ? context.aksen.sukses
                                : totalSelisih < 0
                                ? context.aksen.bahaya
                                : context.aksen.peringatan,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RincianMetodeShift(
                            label: 'Tunai',
                            modal: sesi.kasAwalTunai,
                            omzet: sesi.totalTunai,
                            ikon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _RincianMetodeShift(
                            label: 'QRIS',
                            modal: sesi.kasAwalQris,
                            omzet: sesi.totalQris,
                            ikon: Icons.qr_code_2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _RincianMetodeShift(
                            label: 'Transfer',
                            modal: sesi.kasAwalTransfer,
                            omzet: sesi.totalTransfer,
                            ikon: Icons.account_balance_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Jarak.sm),

              Text(
                'Daftar Transaksi Shift Ini',
                style: context.teks.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Jarak.xs2),

              // Daftar Transaksi pada Sesi Ini
              Expanded(
                child: Bingkai<List<Transaksi>>(
                  ambil: () => Repositori.riwayat(sesiId: sesi.id),
                  rangka: const RangkaDaftar(baris: 4),
                  kosong: (data) => data.isEmpty,
                  saatKosong: const Center(
                    child: Text('Belum ada transaksi pada shift ini.'),
                  ),
                  isi: (context, daftar) {
                    return ListView.separated(
                      itemCount: daftar.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Jarak.xs3),
                      itemBuilder: (context, i) {
                        final t = daftar[i];
                        final (ikon, nada) = switch (t.status) {
                          StatusTransaksi.batal => (
                            Icons.close,
                            NadaIkon.bahaya,
                          ),
                          StatusTransaksi.ditahan => (
                            Icons.schedule_outlined,
                            NadaIkon.peringatan,
                          ),
                          StatusTransaksi.selesai => (
                            Icons.check,
                            NadaIkon.sukses,
                          ),
                        };
                        return BarisDaftar(
                          awalan: IkonKotak(ikon, nada: nada, ukuran: 32),
                          judul: t.nomorStruk,
                          keterangan:
                              '${jam(t.waktu)} · ${t.metode.label} · ${t.jumlahItem} item',
                          akhiran: rupiah(t.total),
                          onTekan: () => LembarStruk.tampilkan(context, t),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RincianMetodeShift extends StatelessWidget {
  const _RincianMetodeShift({
    required this.label,
    required this.modal,
    required this.omzet,
    required this.ikon,
  });

  final String label;
  final int modal;
  final int omzet;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: context.aksen.isian,
        borderRadius: BorderRadius.circular(Lengkung.kecil),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikon, size: 14, color: context.warna.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: context.teks.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            rupiah(omzet),
            style: context.teks.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.warna.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (modal > 0)
            Text(
              'Awal: ${rupiah(modal)}',
              style: context.teks.bodySmall?.copyWith(
                fontSize: 9,
                color: context.warna.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
