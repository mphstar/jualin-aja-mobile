import 'package:flutter/material.dart';

import '../data/contoh.dart';
import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/app_shell.dart';
import '../widgets/bingkai.dart';
import '../widgets/ikon_kotak.dart';
import '../widgets/kartu.dart';
import '../widgets/lencana.dart';
import '../widgets/rangka.dart';
import 'kategori_screen.dart';
import 'profil_screen.dart';
import 'struk_screen.dart';
import 'toko_screen.dart';
import 'perpanjang_screen.dart';
import 'riwayat_bayar_screen.dart';

/// Profil toko, status langganan, dan pengaturan.
class AkunScreen extends StatelessWidget {
  const AkunScreen({
    super.key,
    required this.onGantiTema,
    required this.gelap,
    required this.onKeluar,
  });

  final VoidCallback onGantiTema;
  final bool gelap;
  final VoidCallback onKeluar;

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return ListView(
      padding: padding,
      children: [
        // Profil menggantikan judul "Akun". Di layar yang seluruh isinya
        // tentang satu orang dan satu toko, kata "Akun" tidak menambah apa pun
        // yang tidak sudah terbaca dari nama tokonya sendiri.
        //
        // Ikut mendengarkan [revisiData] karena nama dan tokonya bisa berubah
        // dari dua layar yang dibuka dari sini juga.
        ListenableBuilder(
          listenable: revisiData,
          builder: (context, _) => const _KepalaProfil(),
        ),
        const SizedBox(height: Jarak.md),

        // Langganan adalah permukaan fokus layar ini — satu-satunya hal di
        // sini yang punya tenggat, dan satu-satunya yang berhenti bekerja
        // kalau diabaikan.
        const JudulBagian('Langganan'),
        Bingkai<Langganan>(
          ambil: Repositori.langganan,
          rangka: const RangkaPanel(tinggi: 196),
          isi: (context, l) => _PanelLangganan(langganan: l),
        ),
        const SizedBox(height: Jarak.md),

        const JudulBagian('Toko'),
        // Dua baris di bawah menampilkan angka yang bisa diubah dari layar
        // yang mereka buka sendiri. Tanpa mendengarkan [revisiData], daftar
        // ini masih menulis "4 kategori" tepat setelah pengguna menambah yang
        // kelima — dan menu yang membantah layar yang baru saja ditutup adalah
        // menu yang berhenti dipercaya.
        ListenableBuilder(
          listenable: revisiData,
          builder: (context, _) => KartuDaftar(
            anak: [
              _BarisMenu(
                ikon: Icons.storefront_outlined,
                judul: 'Data toko',
                keterangan: '${tokoContoh.jenisUsaha} · $kotaToko',
                onTekan: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TokoScreen()),
                ),
              ),
              _BarisMenu(
                ikon: Icons.receipt_outlined,
                judul: 'Struk & printer',
                keterangan: 'Kepala struk dan perangkat cetak',
                onTekan: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const StrukScreen()),
                ),
              ),
              _BarisMenu(
                ikon: Icons.category_outlined,
                judul: 'Kategori produk',
                keterangan: '${kategoriContoh.length} kategori',
                onTekan: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const KategoriScreen(),
                  ),
                ),
              ),
              _BarisMenu(
                ikon: Icons.receipt_long_outlined,
                judul: 'Riwayat pembayaran',
                keterangan: 'Tagihan langganan dan statusnya',
                onTekan: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RiwayatBayarScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Jarak.md),

        const JudulBagian('Aplikasi'),
        KartuDaftar(
          anak: [
            _BarisMenu(
              ikon: gelap
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              judul: 'Tampilan',
              keterangan: gelap ? 'Mode gelap' : 'Mode terang',
              onTekan: onGantiTema,
              // Sakelar, bukan panah: hasilnya langsung terjadi di layar ini,
              // tidak membuka halaman lain.
              akhiran: Switch(value: gelap, onChanged: (_) => onGantiTema()),
            ),
            _BarisMenu(
              ikon: Icons.help_outline,
              judul: 'Bantuan',
              keterangan: 'Panduan dan kontak dukungan',
              onTekan: () => _menyusul(context, 'Bantuan'),
            ),
            _BarisMenu(
              ikon: Icons.info_outline,
              judul: 'Tentang aplikasi',
              keterangan: 'Versi tampilan · belum tersambung server',
              onTekan: () => _menyusul(context, 'Tentang aplikasi'),
            ),
          ],
        ),
        const SizedBox(height: Jarak.md),

        const _PeragaanKeadaan(),
        const SizedBox(height: Jarak.md),

        // Keluar berdiri sendiri, bukan baris terakhir dari daftar panjang.
        // Aksi yang membuang keadaan tidak boleh terlihat setara dengan
        // "Bantuan" tepat di atasnya.
        OutlinedButton.icon(
          onPressed: () => _konfirmasiKeluar(context, onKeluar),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Keluar dari akun'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.aksen.bahaya,
            side: BorderSide(
              color: context.aksen.bahaya.withValues(alpha: 0.35),
            ),
          ),
        ),
        const SizedBox(height: Jarak.xs),
        ListenableBuilder(
          listenable: revisiData,
          builder: (context, _) => Center(
            child: Text(
              '${tokoContoh.nama} · ${profilContoh.email}',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static void _menyusul(BuildContext context, String apa) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$apa menyusul.')));
  }

  /// Aksi yang membuang keadaan selalu berdialog. Aturan yang sama dengan
  /// panel web.
  static Future<void> _konfirmasiKeluar(
    BuildContext context,
    VoidCallback onKeluar,
  ) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu memasukkan email dan kata sandi lagi untuk masuk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.aksen.bahaya,
              foregroundColor: context.warna.onError,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ya ?? false) onKeluar();
  }
}

/// Kepala halaman berupa profil, sejajar dengan sapaan di Beranda.
class _KepalaProfil extends StatelessWidget {
  const _KepalaProfil();

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final profil = profilContoh;

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: a.fokus, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            inisial(profil.nama),
            style: context.teks.titleLarge?.copyWith(color: a.atasFokus),
          ),
        ),
        const SizedBox(width: Jarak.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tokoContoh.nama,
                style: context.teks.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${profil.nama} · ${profil.peran}',
                style: context.teks.bodyMedium?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ProfilScreen())),
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Ubah profil',
        ),
      ],
    );
  }
}

/// Permukaan fokus layar Akun.
///
/// Sebelumnya ini kartu putih bergaris, setara dengan "Data toko" dan
/// "Bantuan" di bawahnya — padahal ia satu-satunya hal di layar ini yang punya
/// tenggat, dan satu-satunya yang berhenti bekerja kalau diabaikan. Sekarang
/// **sisa harinya** yang jadi angka besar, bukan nama paketnya: yang dicari
/// orang saat membuka layar ini adalah "masih berapa lama", bukan "paket apa".
class _PanelLangganan extends StatelessWidget {
  const _PanelLangganan({required this.langganan});

  final Langganan langganan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final l = langganan;

    // Bilah kemajuan memperlihatkan berapa banyak periode yang sudah terpakai.
    // "5 hari lagi" saja tidak memberi tahu apakah itu dari 30 hari atau 365.
    final totalHari = l.tanggalBerakhir.difference(l.tanggalMulai).inDays;
    final terpakai = totalHari <= 0
        ? 1.0
        : ((totalHari - l.sisaHari) / totalHari).clamp(0.0, 1.0);

    final warnaBilah = switch (l.status) {
      StatusLangganan.kedaluwarsa => a.bahaya,
      StatusLangganan.akanBerakhir => a.peringatan,
      _ => a.atasFokus,
    };

    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: a.fokus,
        borderRadius: BorderRadius.circular(Lengkung.panel),
        boxShadow: a.bayanganKartu,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.durasi.label.toUpperCase(),
                  style: context.teks.labelSmall?.copyWith(
                    color: a.atasFokusRedup,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Lencana.langganan(l.status),
            ],
          ),
          const SizedBox(height: Jarak.xs2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              sisaHari(l.sisaHari),
              style: context.teks.displaySmall?.copyWith(color: a.atasFokus),
            ),
          ),
          const SizedBox(height: Jarak.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Lengkung.bulat),
            child: LinearProgressIndicator(
              value: terpakai,
              minHeight: 6,
              backgroundColor: a.atasFokusRedup.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(warnaBilah),
            ),
          ),
          const SizedBox(height: Jarak.xs2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mulai ${tanggal(l.tanggalMulai)}',
                  style: context.teks.bodySmall?.copyWith(
                    color: a.atasFokusRedup,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Jarak.xs2),
              Flexible(
                child: Text(
                  'Sampai ${tanggal(l.tanggalBerakhir)}',
                  textAlign: TextAlign.right,
                  style: context.teks.bodySmall?.copyWith(
                    color: a.atasFokusRedup,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.md),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PerpanjangScreen(),
                ),
              ),
              style: FilledButton.styleFrom(
                // Dibalik terhadap panelnya, sama seperti tombol di Beranda.
                backgroundColor: a.atasFokus,
                foregroundColor: a.fokus,
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Perpanjang langganan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisMenu extends StatelessWidget {
  const _BarisMenu({
    required this.ikon,
    required this.judul,
    this.keterangan,
    this.onTekan,
    this.akhiran,
  });

  final IconData ikon;
  final String judul;
  final String? keterangan;
  final VoidCallback? onTekan;

  /// Pengganti panah kanan. Panah menjanjikan halaman lain; kalau hasilnya
  /// justru terjadi di layar ini, panahnya berbohong.
  final Widget? akhiran;

  @override
  Widget build(BuildContext context) {
    return BarisDaftar(
      awalan: IkonKotak(ikon, ukuran: 36),
      judul: judul,
      keterangan: keterangan,
      bawahAkhiran:
          akhiran ??
          Icon(
            Icons.chevron_right,
            size: 20,
            color: context.warna.onSurfaceVariant,
          ),
      onTekan: onTekan,
    );
  }
}

/// Sakelar peragaan empat keadaan.
///
/// Ada supaya keadaan memuat, kosong, dan galat bisa **dilihat**, bukan cuma
/// dipercaya ada. Keadaan yang tidak pernah dibuka adalah keadaan yang tidak
/// pernah benar-benar dirancang — dan biasanya baru ketahuan belum dirancang
/// pada hari jaringan mati.
///
/// Bagian ini hilang saat backend disambung.
class _PeragaanKeadaan extends StatelessWidget {
  const _PeragaanKeadaan();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ModeUji>(
      valueListenable: modeUji,
      builder: (context, mode, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JudulBagian('Peragaan keadaan'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Jarak.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Paksa seluruh layar menampilkan satu keadaan tertentu. '
                    'Hanya alat bantu tahap tampilan — hilang saat backend '
                    'disambung.',
                    style: context.teks.bodySmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: Jarak.xs),
                  Wrap(
                    spacing: Jarak.xs2,
                    runSpacing: Jarak.xs2,
                    children: [
                      for (final m in ModeUji.values)
                        _PilKeadaan(
                          label: switch (m) {
                            ModeUji.normal => 'Normal',
                            ModeUji.memuat => 'Memuat',
                            ModeUji.kosong => 'Kosong',
                            ModeUji.galat => 'Galat',
                          },
                          aktif: mode == m,
                          onTekan: () => modeUji.value = m,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PilKeadaan extends StatelessWidget {
  const _PilKeadaan({
    required this.label,
    required this.aktif,
    required this.onTekan,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: aktif,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: Jarak.xs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? context.aksen.fokus : Colors.transparent,
            borderRadius: BorderRadius.circular(Lengkung.bulat),
            border: Border.all(
              color: aktif ? context.aksen.fokus : context.warna.outline,
            ),
          ),
          child: Text(
            label,
            style: context.teks.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: aktif ? context.aksen.atasFokus : context.warna.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
