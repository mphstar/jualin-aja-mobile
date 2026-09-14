import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Keadaan kosong dan keadaan galat.
///
/// Keduanya memakai bentuk yang sama karena keduanya menjawab pertanyaan yang
/// sama dari pengguna: *"kenapa layarnya kosong, dan apa yang harus saya
/// lakukan?"* Yang membedakan cuma nada dan tombolnya.
///
/// Aturan yang dipegang: **judul menyebut keadaan, keterangan menyebut
/// penyebab, tombol menyebut kata kerja.** "Belum ada apa-apa di sini" tanpa
/// jalan keluar adalah jalan buntu yang sopan.
///
/// Dua hal yang tidak boleh dilanggar di sini:
///
/// * **Lebarnya dibatasi** (420 px). Tanpa batas, di tata letak lebar
///   (rail, ≥ 600 px) panel ini jadi bidang putih selebar layar dengan satu
///   ikon kecil di tengahnya — terbaca seperti layar yang gagal digambar,
///   bukan seperti keterangan.
/// * **Bingkainya tetap garis biasa, termasuk saat galat.** Kroma di aplikasi
///   ini menandai STATUS. Bingkai merah yang mengelilingi seluruh panel membuat
///   gangguan koneksi terbaca sehebat transaksi yang gagal — dan begitu dipakai
///   untuk hal yang bukan status, merahnya berhenti berarti apa-apa.
class Keadaan extends StatelessWidget {
  const Keadaan({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
    this.labelAksi,
    this.onAksi,
    this.aksiWidget,
    this.nada = NadaKeadaan.tenang,
  });

  /// Keadaan galat — nada bahaya, "Coba lagi" sebagai aksi utama.
  const factory Keadaan.galat({
    Key? key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) = _KeadaanGalat;

  /// Keadaan galat untuk bagian layar — satu baris, tanpa judul.
  ///
  /// Dipakai saat panel ini hanya satu bagian dari layar (lihat
  /// `Bingkai.galatPadat`). Satu layar bisa memuat beberapa bagian, dan kalau
  /// semuanya gagal, kartu penuh yang berulang ke bawah terbaca seperti
  /// sekian banyak masalah besar — padahal penyebabnya satu. Bentuk ringkas
  /// menyebut hal yang sama tanpa mengambil alih halaman.
  const factory Keadaan.galatPadat({
    Key? key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) = _KeadaanGalatPadat;

  /// Keadaan galat untuk **seluruh isi tab** — menggantikan halamannya.
  ///
  /// Dipasang di akar tiap tab (lihat `BentukGalat.halaman`). Saat server
  /// tidak terjangkau, halaman yang isinya setengah jadi lebih membingungkan
  /// daripada tidak ada halaman sama sekali: pengguna melihat layar yang
  /// rusak, bukan layar yang sedang menunggu. Karena itu bentuk ini tidak
  /// menyisakan apa pun dari isi tab — termasuk judul, saringan, dan tombol
  /// yang tidak ada gunanya selama datanya belum bisa diambil.
  const factory Keadaan.galatHalaman({
    Key? key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) = _KeadaanGalatHalaman;

  final IconData ikon;
  final String judul;
  final String keterangan;
  final String? labelAksi;
  final VoidCallback? onAksi;
  final Widget? aksiWidget;
  final NadaKeadaan nada;

  /// Lebar maksimum panel. Di atas ini barisnya tidak lagi terbaca lebih baik,
  /// dan panelnya hanya jadi ruang putih.
  static const _lebarMaks = 420.0;

  @override
  Widget build(BuildContext context) {
    final bahaya = nada == NadaKeadaan.bahaya;

    // `heightFactor: 1` menahan panelnya setinggi isinya. Tanpa itu `Align`
    // ikut mengisi tinggi yang tersedia, dan panel yang tadinya diletakkan di
    // tengah oleh induknya melompat ke atas.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _lebarMaks),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Jarak.md,
            vertical: Jarak.md,
          ),
          decoration: BoxDecoration(
            color: context.warna.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(Lengkung.panel),
            border: Border.all(color: context.warna.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bahaya
                      ? context.aksen.bahayaLembut
                      : context.aksen.isian,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  ikon,
                  size: 24,
                  color: bahaya
                      ? context.aksen.bahaya
                      : context.warna.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Jarak.xs),
              Text(
                judul,
                textAlign: TextAlign.center,
                style: context.teks.titleMedium,
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  keterangan,
                  textAlign: TextAlign.center,
                  style: context.teks.bodyMedium?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
              if (aksiWidget != null) ...[
                const SizedBox(height: Jarak.sm),
                aksiWidget!,
              ] else if (labelAksi != null && onAksi != null) ...[
                const SizedBox(height: Jarak.sm),
                // Saat galat, tombol ini satu-satunya jalan keluar — jadi ia
                // aksi utama (tinta). Di atas panel putih, OutlinedButton
                // nyaris tak berbingkai; tombol yang tak terlihat lebih buruk
                // daripada tombol yang tegas.
                if (bahaya)
                  FilledButton(onPressed: onAksi, child: Text(labelAksi!))
                else
                  OutlinedButton(onPressed: onAksi, child: Text(labelAksi!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum NadaKeadaan { tenang, bahaya }

class _KeadaanGalat extends Keadaan {
  const _KeadaanGalat({
    super.key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) : super(
         ikon: Icons.cloud_off_outlined,
         judul: 'Gagal memuat',
         keterangan: pesan,
         labelAksi: 'Coba lagi',
         onAksi: onCobaLagi,
         nada: NadaKeadaan.bahaya,
       );
}

/// Bentuk ringkas: satu baris, tanpa judul dan tanpa kartu penuh.
///
/// Judul "Gagal memuat" sengaja dibuang di sini. Di bagian layar, kalimat
/// penyebabnya sendiri sudah menyebut apa yang terjadi ("Tidak bisa terhubung
/// ke server."), dan mengulanginya dalam judul hanya menambah tinggi.
class _KeadaanGalatPadat extends Keadaan {
  const _KeadaanGalatPadat({
    super.key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) : super(
         ikon: Icons.cloud_off_outlined,
         judul: 'Gagal memuat',
         keterangan: pesan,
         labelAksi: 'Coba lagi',
         onAksi: onCobaLagi,
         nada: NadaKeadaan.bahaya,
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        Jarak.xs,
        Jarak.xs2,
        Jarak.xs3,
        Jarak.xs2,
      ),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: context.aksen.bahaya),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              keterangan,
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Jarak.xs2),
          TextButton(onPressed: onAksi, child: Text(labelAksi!)),
        ],
      ),
    );
  }
}

/// Bentuk satu halaman penuh — dipakai saat SELURUH isi tab tidak bisa dimuat.
///
/// Tanpa kartu dan tanpa bingkai: tidak ada lagi yang perlu dibingkai kalau
/// halamannya memang tidak ditampilkan.
class _KeadaanGalatHalaman extends Keadaan {
  const _KeadaanGalatHalaman({
    super.key,
    required String pesan,
    required VoidCallback onCobaLagi,
  }) : super(
         ikon: Icons.cloud_off_outlined,
         judul: 'Gagal memuat',
         keterangan: pesan,
         labelAksi: 'Coba lagi',
         onAksi: onCobaLagi,
         nada: NadaKeadaan.bahaya,
       );

  @override
  Widget build(BuildContext context) {
    return Center(
      // Bisa digulir: di layar pendek dengan ukuran huruf sistem yang
      // diperbesar, tombol "Coba lagi" tidak boleh jatuh di luar jangkauan.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Jarak.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.aksen.bahayaLembut,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(ikon, size: 28, color: context.aksen.bahaya),
              ),
              const SizedBox(height: Jarak.sm),
              Text(
                judul,
                textAlign: TextAlign.center,
                style: context.teks.titleLarge,
              ),
              const SizedBox(height: Jarak.xs2),
              Text(
                keterangan,
                textAlign: TextAlign.center,
                style: context.teks.bodyMedium?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: Jarak.md),
              FilledButton(onPressed: onAksi, child: Text(labelAksi!)),
            ],
          ),
        ),
      ),
    );
  }
}
