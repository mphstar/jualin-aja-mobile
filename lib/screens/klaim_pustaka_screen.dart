import 'package:flutter/material.dart';

import '../data/klaim.dart';
import '../data/model.dart';
import '../data/populer.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/bingkai.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/penanda_populer.dart';
import '../widgets/rangka.dart';
import '../widgets/sampul_ebook.dart';
import 'baca_screen.dart';

/// Klaim jatah langganan — satu Resep dan satu Prompt gratis per siklus.
///
/// Dijangkau dari dua tempat: tombol di layar pembayaran yang baru lunas, dan
/// banner Pustaka untuk jatah yang dulu tidak dipakai. Sengaja **tidak**
/// dibuka otomatis — jatahnya hidup di server dan tidak hangus, jadi memaksa
/// berpindah hanya membuat pengguna melewatinya tanpa sempat melihat masa
/// aktif langganannya. Isinya dua bagian tetap, Resep lalu Prompt, dan tiap
/// bagian hanya menampilkan konten yang jatahnya masih tersedia.
///
/// Daftarnya menyegar sendiri setelah klaim: `Repositori.klaimPustaka`
/// menaikkan `revisiData`, dan `Bingkai` mendengarkannya. Tidak ada satu baris
/// pun kode muat-ulang manual di sini.
class KlaimPustakaScreen extends StatelessWidget {
  const KlaimPustakaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Klaim gratis')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Bingkai<List<Ebook>>(
              ambil: Repositori.ebook,
              rangka: _Rangka(padding: padding),
              kosong: (daftar) => daftar.isEmpty,
              saatKosong: ListView(
                padding: padding,
                children: [
                  const KepalaHalaman(
                    judul: 'Klaim gratis',
                    keterangan: 'Langgananmu aktif, tapi Pustaka masih kosong.',
                  ),
                  const SizedBox(height: Jarak.md),
                  Keadaan(
                    ikon: Icons.auto_stories_outlined,
                    judul: 'Belum ada konten',
                    keterangan:
                        'Katalog Pustaka bertambah dari waktu ke waktu. Jatah '
                        'klaimmu tetap tersimpan sampai kontennya terbit.',
                    labelAksi: 'Selesai',
                    onAksi: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              isi: (context, daftar) =>
                  _Isi(daftar: daftar, padding: padding),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Isi
// ---------------------------------------------------------------------------

class _Isi extends StatefulWidget {
  const _Isi({required this.daftar, required this.padding});

  final List<Ebook> daftar;
  final EdgeInsets padding;

  @override
  State<_Isi> createState() => _IsiState();
}

class _IsiState extends State<_Isi> {
  /// Id konten yang sedang diproses — menahan ketukan ganda pada tombol Klaim.
  String? _sedangKlaim;

  Future<void> _klaim(Ebook ebook) async {
    if (_sedangKlaim != null) return;
    setState(() => _sedangKlaim = ebook.id);

    try {
      final pesan = await Repositori.klaimPustaka(ebook.id);
      if (!mounted) return;
      _kabar(
        pesan,
        aksi: SnackBarAction(
          label: 'Baca sekarang',
          onPressed: () => _baca(ebook),
        ),
      );
    } on GagalMuat catch (e) {
      if (!mounted) return;
      _kabar(e.pesan);
    } finally {
      if (mounted) setState(() => _sedangKlaim = null);
    }
  }

  Future<void> _baca(Ebook ebook) async {
    try {
      final url = await Repositori.bukaEbook(ebook.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BacaScreen(judul: ebook.judul, url: url),
        ),
      );
    } on GagalMuat catch (e) {
      if (!mounted) return;
      _kabar(e.pesan);
    }
  }

  void _kabar(String pesan, {SnackBarAction? aksi}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan), action: aksi));
  }

  @override
  Widget build(BuildContext context) {
    final ringkasan = ringkasanKlaim(widget.daftar);

    // Dari katalog UTUH, bukan dari yang bisa diklaim saja: pemenang
    // "Terpopuler" ditentukan seluruh katalog, dan menghitungnya dari daftar
    // yang sudah disaring jatah akan mengangkat konten yang bukan tiga teratas.
    final populer = idTerpopuler(widget.daftar);

    return ListView(
      padding: widget.padding,
      children: [
        Text(
          'Langgananmu aktif. Pilih satu Resep dan satu Prompt untuk dibuka '
          'gratis. Belum mau memilih sekarang? Jatahnya tidak hangus — bisa '
          'diklaim kapan saja dari Pustaka.',
          style: context.teks.bodyMedium?.copyWith(
            color: context.warna.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: Jarak.md),

        if (ringkasan.selesai)
          Keadaan(
            ikon: Icons.card_giftcard_rounded,
            judul: ringkasan.jatahTerpakai > 0
                ? 'Jatah siklus ini sudah terpakai'
                : 'Belum ada yang bisa diklaim',
            keterangan: ringkasan.jatahTerpakai > 0
                ? 'Kamu sudah memakai jatah klaim siklus langganan ini. Jatah '
                      'baru terbuka sendiri begitu langganan diperpanjang, dan '
                      'konten lain tetap bisa dibeli satuan dari Pustaka.'
                : 'Belum ada konten yang terbit di Pustaka. Katalognya '
                      'bertambah dari waktu ke waktu — tidak perlu melakukan '
                      'apa pun.',
            labelAksi: 'Selesai',
            onAksi: () => Navigator.of(context).maybePop(),
          )
        else ...[
          for (final bagian in ringkasan.bagian) ...[
            JudulBagian(bagian.label),
            _Bagian(
              bagian: bagian,
              sedangKlaim: _sedangKlaim,
              populer: populer,
              onKlaim: _klaim,
            ),
            const SizedBox(height: Jarak.md),
          ],
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Selesai'),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Satu bagian (Resep / Prompt)
// ---------------------------------------------------------------------------

class _Bagian extends StatelessWidget {
  const _Bagian({
    required this.bagian,
    required this.sedangKlaim,
    required this.populer,
    required this.onKlaim,
  });

  final BagianKlaim bagian;
  final String? sedangKlaim;

  /// Id konten yang menyandang lencana "Terpopuler" — diputuskan sekali untuk
  /// seluruh katalog, bukan per bagian.
  final Set<String> populer;

  final Future<void> Function(Ebook) onKlaim;

  @override
  Widget build(BuildContext context) {
    switch (bagian.status) {
      // Bukan jatah yang habis — kontennya memang belum ada. Membedakan
      // keduanya penting: "jatah habis" membuat orang merasa kehilangan
      // sesuatu yang sebenarnya masih menunggu.
      case StatusJatah.kosong:
        return _Catatan(
          ikon: Icons.hourglass_empty_rounded,
          teks: 'Belum ada ${bagian.label} yang terbit. Bagian ini terisi '
              'sendiri begitu admin menerbitkannya.',
        );

      case StatusJatah.terpakai:
        return _Catatan(
          ikon: Icons.check_circle_outline_rounded,
          teks: 'Jatah ${bagian.label} untuk siklus langganan ini sudah '
              'terpakai. Jatah baru terbuka saat langganan diperpanjang.',
        );

      case StatusJatah.tersedia:
        return Column(
          children: [
            for (final ebook in bagian.bisaDiklaim)
              Padding(
                padding: const EdgeInsets.only(bottom: Jarak.xs2),
                child: _KartuKlaim(
                  ebook: ebook,
                  memproses: sedangKlaim == ebook.id,
                  populer: populer.contains(ebook.id),
                  onKlaim: () => onKlaim(ebook),
                ),
              ),
          ],
        );
    }
  }
}

/// Keterangan tenang untuk bagian yang tidak punya konten untuk diklaim.
class _Catatan extends StatelessWidget {
  const _Catatan({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Lengkung.kecil),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: context.warna.onSurfaceVariant),
          const SizedBox(width: Jarak.xs2),
          Expanded(
            child: Text(
              teks,
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu konten yang bisa diklaim — bentuknya mengikuti kartu Pustaka.
class _KartuKlaim extends StatelessWidget {
  const _KartuKlaim({
    required this.ebook,
    required this.memproses,
    required this.populer,
    required this.onKlaim,
  });

  final Ebook ebook;
  final bool memproses;
  final bool populer;
  final VoidCallback onKlaim;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Jarak.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              height: 76,
              child: SampulEbook(
                judul: ebook.judul,
                kategori: ebook.labelKategori,
                jenis: ebook.jenis,
                coverUrl: ebook.coverUrl,
              ),
            ),
            const SizedBox(width: Jarak.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ebook.judul,
                    style: context.teks.titleSmall?.copyWith(height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  PenandaPopuler(
                    jumlahUnduhan: ebook.jumlahUnduhan,
                    populer: populer,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ebook.labelKategori} · ${ebook.jumlahHalaman} hal',
                    style: context.teks.bodySmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Jarak.xs2),
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      onPressed: memproses ? null : onKlaim,
                      icon: memproses
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.warna.onPrimary,
                              ),
                            )
                          : const Icon(Icons.card_giftcard_rounded, size: 17),
                      label: const Text('Klaim'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rangka pemuatan
// ---------------------------------------------------------------------------

class _Rangka extends StatelessWidget {
  const _Rangka({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: const [
        Rangka(tinggi: 44),
        SizedBox(height: Jarak.md),
        JudulBagian('Resep'),
        RangkaDaftar(baris: 2, tinggiBaris: 92),
        SizedBox(height: Jarak.md),
        JudulBagian('Prompt'),
        RangkaDaftar(baris: 2, tinggiBaris: 92),
      ],
    );
  }
}
