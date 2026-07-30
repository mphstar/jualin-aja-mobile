import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/pencetak_struk.dart';
import 'kartu.dart';
import 'tombol_pil.dart';

/// Lembar bawah pemilihan perangkat printer Bluetooth termal.
class LembarPilihPrinter extends StatefulWidget {
  const LembarPilihPrinter({super.key});

  static Future<BluetoothDevice?> tampilkan(BuildContext context) {
    return showModalBottomSheet<BluetoothDevice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const LembarPilihPrinter(),
    );
  }

  @override
  State<LembarPilihPrinter> createState() => _LembarPilihPrinterState();
}

class _LembarPilihPrinterState extends State<LembarPilihPrinter> {
  List<BluetoothDevice> _perangkat = [];
  BluetoothDevice? _terpilih;
  bool _memuat = true;
  bool _menghubungkan = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      final daftar = await PencetakStruk.ambilDaftarBluetooth();
      final tersimpan = await PencetakStruk.ambilPrinterTersimpan();

      if (!mounted) return;
      setState(() {
        _perangkat = daftar;
        if (tersimpan != null) {
          final indeks = daftar.indexWhere((d) => d.address == tersimpan.address);
          _terpilih = indeks >= 0 ? daftar[indeks] : tersimpan;
        }
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _galat = 'Gagal memuat perangkat Bluetooth: $e';
      });
    }
  }

  Future<void> _pilih(BluetoothDevice device) async {
    setState(() {
      _terpilih = device;
      _menghubungkan = true;
      _galat = null;
    });

    try {
      await PencetakStruk.simpanPrinterPilihan(device);
      final terhubung = await PencetakStruk.hubungkanBluetooth(device);

      if (!mounted) return;
      setState(() => _menghubungkan = false);

      if (terhubung) {
        Navigator.of(context).pop(device);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Printer ${device.name ?? device.address} terhubung'),
            ),
          );
      } else {
        setState(() {
          _galat = 'Gagal terhubung ke printer. Pastikan printer Bluetooth menyala.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menghubungkan = false;
        _galat = 'Kesalahan koneksi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tinggiMaks = MediaQuery.sizeOf(context).height * 0.75;
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
                  Expanded(
                    child: Text('Pilih Printer Bluetooth', style: context.teks.titleLarge),
                  ),
                  IconButton(
                    onPressed: _memuat ? null : _muatData,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Pindai ulang',
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Pastikan printer termal Bluetooth sudah dipasangkan (paired) '
                'di pengaturan Bluetooth HP Anda.',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: Jarak.sm),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_memuat) ...[
                        const Padding(
                          padding: EdgeInsets.all(Jarak.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ] else if (_perangkat.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(Jarak.sm),
                          decoration: BoxDecoration(
                            color: context.aksen.kartuAlt,
                            borderRadius: BorderRadius.circular(Lengkung.kontrol),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.bluetooth_disabled_outlined,
                                size: 32,
                                color: context.warna.onSurfaceVariant,
                              ),
                              const SizedBox(height: Jarak.xs2),
                              Text(
                                'Tidak ada printer Bluetooth terpasang',
                                style: context.teks.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Buka Pengaturan HP > Bluetooth, sambungkan printer Anda, '
                                'lalu tekan Pindai Ulang.',
                                textAlign: TextAlign.center,
                                style: context.teks.bodySmall?.copyWith(
                                  color: context.warna.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        KartuDaftar(
                          anak: [
                            for (final d in _perangkat)
                              BarisDaftar(
                                awalan: Icon(
                                  Icons.print_outlined,
                                  size: 22,
                                  color: _terpilih?.address == d.address
                                      ? context.warna.onSurface
                                      : context.warna.onSurfaceVariant,
                                ),
                                judul: d.name ?? 'Printer Tanpa Nama',
                                keterangan: d.address ?? '',
                                bawahAkhiran: _terpilih?.address == d.address
                                    ? Icon(
                                        Icons.check_circle,
                                        size: 20,
                                        color: context.aksen.sukses,
                                      )
                                    : const Icon(Icons.chevron_right, size: 20),
                                onTekan: _menghubungkan ? null : () => _pilih(d),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_galat != null) ...[
                const SizedBox(height: Jarak.xs),
                Text(
                  _galat!,
                  style: context.teks.bodySmall?.copyWith(
                    color: context.aksen.bahaya,
                  ),
                ),
              ],

              const SizedBox(height: Jarak.md),
              TombolPilGaris(
                label: 'Batal',
                onTekan: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
