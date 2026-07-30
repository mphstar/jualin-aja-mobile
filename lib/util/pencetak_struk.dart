import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/model.dart';
import '../data/sesi_kasir.dart';
import '../widgets/lembar_pilih_printer.dart';
import 'format.dart';

/// Layanan pencetak struk termal & pengelola Bluetooth.
///
/// Menyusun tata letak (*layout*) struk berbasis format roll 58 mm atau 80 mm
/// sesuai [PengaturanStruk] serta menangani alur cetak Bluetooth ESC/POS langsung.
abstract class PencetakStruk {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  static const _kunciMac = 'printer_bt_mac';
  static const _kunciNama = 'printer_bt_nama';

  /// Transaksi uji coba untuk pratinjau dan tes printer.
  static final _transaksiUjiCoba = Transaksi(
    id: 'sample',
    nomorStruk: 'STRUK-UJI-COBA',
    waktu: DateTime.now(),
    baris: const [
      BarisStruk(
        produkId: 'sample-1',
        nama: 'Kopi Susu Gula Aren',
        jumlah: 2,
        hargaSatuan: 18000,
      ),
      BarisStruk(
        produkId: 'sample-2',
        nama: 'Pisang Goreng',
        jumlah: 1,
        hargaSatuan: 12000,
      ),
    ],
    metode: MetodeBayar.tunai,
    status: StatusTransaksi.selesai,
    uangDiterima: 50000,
  );

  // -------------------------------------------------------------------------
  // Layanan Bluetooth Printer
  // -------------------------------------------------------------------------

  /// Ambil daftar perangkat Bluetooth yang sudah dipasangkan (paired).
  static Future<List<BluetoothDevice>> ambilDaftarBluetooth() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (_) {
      return [];
    }
  }

  /// Ambil data printer Bluetooth yang disimpan di lokal.
  static Future<BluetoothDevice?> ambilPrinterTersimpan() async {
    final sp = await SharedPreferences.getInstance();
    final mac = sp.getString(_kunciMac);
    final nama = sp.getString(_kunciNama);
    if (mac == null || mac.isEmpty) return null;
    return BluetoothDevice(nama ?? 'Printer Bluetooth', mac);
  }

  /// Simpan pilihan printer Bluetooth di lokal HP.
  static Future<void> simpanPrinterPilihan(BluetoothDevice device) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kunciMac, device.address ?? '');
    await sp.setString(_kunciNama, device.name ?? 'Printer Bluetooth');
  }

  /// Hubungkan socket ke printer Bluetooth.
  static Future<bool> hubungkanBluetooth(BluetoothDevice device) async {
    final terhubung = await _bluetooth.isConnected;
    if (terhubung == true) return true;

    try {
      await _bluetooth.connect(device);
      return (await _bluetooth.isConnected) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cetak langsung teks & perintah ESC/POS via socket Bluetooth ke printer termal.
  static Future<bool> cetakDirectBluetooth({
    required Toko toko,
    required PengaturanStruk pengaturan,
    required Transaksi transaksi,
    BluetoothDevice? device,
  }) async {
    final target = device ?? await ambilPrinterTersimpan();
    if (target == null) return false;

    final terhubung = await hubungkanBluetooth(target);
    if (!terhubung) return false;

    final pemisah =
        pengaturan.lebar == LebarKertas.mm58
            ? '--------------------------------'
            : '------------------------------------------------';

    // Header Struk (Toko & Info)
    _bluetooth.printCustom(toko.nama, 1, 1);
    if (pengaturan.tampilkanAlamat && toko.alamat.isNotEmpty) {
      _bluetooth.printCustom(toko.alamat, 0, 1);
    }
    if (pengaturan.tampilkanTelepon && toko.telepon.isNotEmpty) {
      _bluetooth.printCustom('Telp: ${toko.telepon}', 0, 1);
    }
    if (pengaturan.kepala.trim().isNotEmpty) {
      _bluetooth.printCustom(pengaturan.kepala.trim(), 0, 1);
    }

    _bluetooth.printCustom(pemisah, 0, 1);
    _bluetooth.printCustom('No: ${transaksi.nomorStruk}', 0, 0);
    _bluetooth.printCustom(
      'Waktu: ${tanggal(transaksi.waktu)} ${jam(transaksi.waktu)}',
      0,
      0,
    );
    _bluetooth.printCustom('Metode: ${transaksi.metode.label}', 0, 0);
    if (pengaturan.tampilkanNamaKasir) {
      _bluetooth.printCustom('Kasir: Pemilik', 0, 0);
    }

    _bluetooth.printCustom(pemisah, 0, 1);

    // Daftar Barang
    for (final b in transaksi.baris) {
      _bluetooth.printCustom(b.nama, 0, 0);
      _bluetooth.printCustom(
        '  ${b.jumlah} x ${rupiah(b.hargaSatuan)} = ${rupiah(b.subtotal)}',
        0,
        2,
      );
    }

    _bluetooth.printCustom(pemisah, 0, 1);

    // Total & Pembayaran
    if (transaksi.adaDiskon) {
      _bluetooth.printCustom('Subtotal: ${rupiah(transaksi.subtotal)}', 0, 2);
      final labelDiskon = transaksi.diskonTipe == 'PERSEN'
          ? 'Diskon (${transaksi.diskonNilai}%): -${rupiah(transaksi.diskonNominal)}'
          : 'Diskon: -${rupiah(transaksi.diskonNominal)}';
      _bluetooth.printCustom(labelDiskon, 0, 2);
    }

    _bluetooth.printCustom('TOTAL: ${rupiah(transaksi.total)}', 1, 2);
    if (transaksi.uangDiterima != null && !transaksi.piutang) {
      _bluetooth.printCustom(
        'Tunai: ${rupiah(transaksi.uangDiterima!)}',
        0,
        2,
      );
      if (transaksi.kembalian case final kembalian?) {
        _bluetooth.printCustom('Kembali: ${rupiah(kembalian)}', 0, 2);
      }
    }
    if (transaksi.piutang) {
      _bluetooth.printCustom(
        'Status: Piutang (${transaksi.pelanggan ?? "Belum Lunas"})',
        0,
        2,
      );
    }

    _bluetooth.printCustom(pemisah, 0, 1);

    // Footer Struk
    if (pengaturan.kaki.trim().isNotEmpty) {
      _bluetooth.printCustom(pengaturan.kaki.trim(), 0, 1);
    }
    _bluetooth.printCustom('Terima kasih atas kunjungan Anda', 0, 1);

    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();

    return true;
  }

  /// Alur Cetak Otomatis Bluetooth:
  /// Cek printer tersimpan -> Hubungkan -> Cetak. Jika belum ada printer, buka pemilih device.
  static Future<void> cetakOtomatisBluetooth(
    BuildContext context, {
    required Toko toko,
    required PengaturanStruk pengaturan,
    required Transaksi transaksi,
  }) async {
    var device = await ambilPrinterTersimpan();

    if (device == null) {
      if (!context.mounted) return;
      device = await LembarPilihPrinter.tampilkan(context);
      if (device == null) return;
    }

    if (!context.mounted) return;
    final sukses = await cetakDirectBluetooth(
      toko: toko,
      pengaturan: pengaturan,
      transaksi: transaksi,
      device: device,
    );

    if (!sukses && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mencetak ke Bluetooth ${device.name ?? ""}. Pastikan Bluetooth HP aktif.',
            ),
            action: SnackBarAction(
              label: 'Ganti Printer',
              onPressed: () => LembarPilihPrinter.tampilkan(context),
            ),
          ),
        );
    }
  }

  // -------------------------------------------------------------------------
  // Layanan PDF Fallback & Share
  // -------------------------------------------------------------------------

  /// Buat dokumen PDF struk termal.
  static Future<Uint8List> buatPdfStruk({
    required Toko toko,
    required PengaturanStruk pengaturan,
    required Transaksi transaksi,
  }) async {
    final doc = pw.Document();

    final formatHalaman =
        pengaturan.lebar == LebarKertas.mm58
            ? PdfPageFormat(58 * PdfPageFormat.mm, double.infinity)
            : PdfPageFormat.roll80;

    final fontMonospace = await PdfGoogleFonts.robotoMonoRegular();
    final fontMonospaceBold = await PdfGoogleFonts.robotoMonoBold();

    doc.addPage(
      pw.Page(
        pageFormat: formatHalaman.copyWith(
          marginTop: 4 * PdfPageFormat.mm,
          marginBottom: 6 * PdfPageFormat.mm,
          marginLeft: 4 * PdfPageFormat.mm,
          marginRight: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          final gayaMono = pw.TextStyle(
            font: fontMonospace,
            fontSize: 9,
            color: PdfColors.black,
          );
          final gayaMonoTebal = pw.TextStyle(
            font: fontMonospaceBold,
            fontSize: 9,
            color: PdfColors.black,
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header Identitas Toko
              pw.Text(
                toko.nama,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontMonospaceBold,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (pengaturan.tampilkanAlamat && toko.alamat.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  toko.alamat,
                  textAlign: pw.TextAlign.center,
                  style: gayaMono.copyWith(fontSize: 8),
                ),
              ],
              if (pengaturan.tampilkanTelepon && toko.telepon.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'Telp: ${toko.telepon}',
                  textAlign: pw.TextAlign.center,
                  style: gayaMono.copyWith(fontSize: 8),
                ),
              ],
              if (pengaturan.kepala.trim().isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  pengaturan.kepala.trim(),
                  textAlign: pw.TextAlign.center,
                  style: gayaMono.copyWith(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Rincian Waktu & Nomor Struk
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No: ${transaksi.nomorStruk}', style: gayaMono),
                  pw.Text(jam(transaksi.waktu), style: gayaMono),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(tanggal(transaksi.waktu), style: gayaMono),
                  pw.Text('Metode: ${transaksi.metode.label}', style: gayaMono),
                ],
              ),
              if (pengaturan.tampilkanNamaKasir) ...[
                pw.Text('Kasir: Pemilik', style: gayaMono),
              ],

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Daftar Barang
              for (final b in transaksi.baris) ...[
                pw.Text(b.nama, style: gayaMonoTebal),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '  ${b.jumlah} x ${rupiah(b.hargaSatuan)}',
                      style: gayaMono,
                    ),
                    pw.Text(rupiah(b.subtotal), style: gayaMono),
                  ],
                ),
                pw.SizedBox(height: 2),
              ],

              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Total & Pembayaran
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: gayaMonoTebal.copyWith(fontSize: 10)),
                  pw.Text(
                    rupiah(transaksi.total),
                    style: gayaMonoTebal.copyWith(fontSize: 10),
                  ),
                ],
              ),

              if (transaksi.uangDiterima != null && !transaksi.piutang) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bayar Tunai', style: gayaMono),
                    pw.Text(
                      rupiah(transaksi.uangDiterima!),
                      style: gayaMono,
                    ),
                  ],
                ),
                if (transaksi.kembalian case final kembalian?) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Kembali', style: gayaMono),
                      pw.Text(rupiah(kembalian), style: gayaMono),
                    ],
                  ),
                ],
              ],

              if (transaksi.piutang) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Status', style: gayaMonoTebal),
                    pw.Text(
                      'Piutang (${transaksi.pelanggan ?? "Belum Lunas"})',
                      style: gayaMonoTebal,
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Footer Struk
              if (pengaturan.kaki.trim().isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  pengaturan.kaki.trim(),
                  textAlign: pw.TextAlign.center,
                  style: gayaMono.copyWith(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text(
                'Terima kasih atas kunjungan Anda',
                textAlign: pw.TextAlign.center,
                style: gayaMono.copyWith(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Cetak PDF via dialog cetak sistem.
  static Future<void> cetakPdfDialog(
    BuildContext context, {
    required Toko toko,
    required PengaturanStruk pengaturan,
    required Transaksi transaksi,
  }) async {
    final pdfBytes = await buatPdfStruk(
      toko: toko,
      pengaturan: pengaturan,
      transaksi: transaksi,
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Struk_${transaksi.nomorStruk}',
    );
  }

  /// Bagikan file PDF struk ke aplikasi lain (WhatsApp/Email/File).
  static Future<void> bagikanStruk(
    BuildContext context, {
    required Toko toko,
    required PengaturanStruk pengaturan,
    required Transaksi transaksi,
  }) async {
    final pdfBytes = await buatPdfStruk(
      toko: toko,
      pengaturan: pengaturan,
      transaksi: transaksi,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Struk_${transaksi.nomorStruk}.pdf',
    );
  }

  /// Uji coba cetak Bluetooth langsung dengan data transaksi sampel.
  static Future<void> cetakStrukUjiCoba(
    BuildContext context, {
    required Toko toko,
    required PengaturanStruk pengaturan,
  }) async {
    await cetakOtomatisBluetooth(
      context,
      toko: toko,
      pengaturan: pengaturan,
      transaksi: _transaksiUjiCoba,
    );
  }

  /// Uji coba bagikan struk contoh dengan data transaksi sampel.
  static Future<void> bagikanStrukUjiCoba(
    BuildContext context, {
    required Toko toko,
    required PengaturanStruk pengaturan,
  }) async {
    await bagikanStruk(
      context,
      toko: toko,
      pengaturan: pengaturan,
      transaksi: _transaksiUjiCoba,
    );
  }

  /// Cetak Laporan Setoran Shift Kasir ke printer Bluetooth / ESC/POS.
  static Future<bool> cetakLaporanShiftBluetooth(
    BuildContext context, {
    required Toko toko,
    required PengaturanStruk pengaturan,
    required SesiKasir sesi,
    BluetoothDevice? device,
  }) async {
    final target = device ?? await ambilPrinterTersimpan();
    if (target == null) return false;

    final terhubung = await hubungkanBluetooth(target);
    if (!terhubung) return false;

    final pemisah = pengaturan.lebar == LebarKertas.mm58
        ? '--------------------------------'
        : '------------------------------------------------';

    _bluetooth.printCustom(toko.nama, 1, 1);
    _bluetooth.printCustom('LAPORAN SETORAN SHIFT', 1, 1);
    _bluetooth.printCustom(pemisah, 0, 1);

    _bluetooth.printCustom('Kasir: ${sesi.namaKasir}', 0, 0);
    _bluetooth.printCustom(
      'Buka: ${tanggal(sesi.waktuBuka)} ${jam(sesi.waktuBuka)}',
      0,
      0,
    );
    if (sesi.waktuTutup != null) {
      _bluetooth.printCustom(
        'Tutup: ${tanggal(sesi.waktuTutup!)} ${jam(sesi.waktuTutup!)}',
        0,
        0,
      );
    }
    _bluetooth.printCustom('Jumlah Transaksi: ${sesi.jumlahTransaksi}', 0, 0);
    _bluetooth.printCustom(pemisah, 0, 1);

    _bluetooth.printCustom('KAS AWAL (MODAL):', 0, 0);
    _bluetooth.printCustom('  Tunai: ${rupiah(sesi.kasAwalTunai)}', 0, 0);
    _bluetooth.printCustom('  QRIS: ${rupiah(sesi.kasAwalQris)}', 0, 0);
    _bluetooth.printCustom('  Transfer: ${rupiah(sesi.kasAwalTransfer)}', 0, 0);
    _bluetooth.printCustom('  Total Modal: ${rupiah(sesi.totalKasAwal)}', 0, 2);

    _bluetooth.printCustom(pemisah, 0, 1);
    _bluetooth.printCustom('PENJUALAN SHIFT:', 0, 0);
    _bluetooth.printCustom('  Tunai: ${rupiah(sesi.totalTunai)}', 0, 0);
    _bluetooth.printCustom('  QRIS: ${rupiah(sesi.totalQris)}', 0, 0);
    _bluetooth.printCustom('  Transfer: ${rupiah(sesi.totalTransfer)}', 0, 0);
    _bluetooth.printCustom('  Total Omzet: ${rupiah(sesi.totalPenjualan)}', 0, 2);

    _bluetooth.printCustom(pemisah, 0, 1);
    _bluetooth.printCustom('REKONSILIASI KAS:', 0, 0);
    _bluetooth.printCustom('  Ekspektasi: ${rupiah(sesi.totalEkspektasi)}', 0, 0);
    _bluetooth.printCustom('  Setoran Fisik: ${rupiah(sesi.totalKasFisik)}', 0, 0);
    final statusSelisih = sesi.totalSelisih == 0
        ? 'Pas (Rp 0)'
        : (sesi.totalSelisih < 0 ? 'Kurang (${rupiah(sesi.totalSelisih)})' : 'Lebih (+${rupiah(sesi.totalSelisih)})');
    _bluetooth.printCustom('  Selisih: $statusSelisih', 1, 2);

    if (sesi.catatan != null && sesi.catatan!.isNotEmpty) {
      _bluetooth.printCustom('Catatan: ${sesi.catatan}', 0, 0);
    }

    _bluetooth.printCustom(pemisah, 0, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();

    return true;
  }
}
