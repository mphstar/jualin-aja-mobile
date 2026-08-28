import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/bingkai.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/modal_fitur_terkunci.dart';
import '../widgets/rangka.dart';
import '../widgets/sampul_ebook.dart';
import 'baca_screen.dart';

/// Pustaka konten: resep dan prompt berbentuk PDF.
///
/// Seluruh data dibaca langsung dari backend (`Repositori.ebook()`), tidak
/// pernah dari data contoh. Konten terbit terbuka untuk langganan yang masih
/// berjalan (PRD §4.3); kalau langganan mati, Pustaka terkunci.
class PustakaScreen extends StatelessWidget {
  PustakaScreen({super.key, this.onKeAkun});

  final VoidCallback? onKeAkun;

  /// Untuk menarik-untuk-segar daftar Pustaka.
  final _kunci = GlobalKey<BingkaiState<(Langganan, List<Ebook>)>>();

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return Bingkai<(Langganan, List<Ebook>)>(
      key: _kunci,
      ambil: () async {
        final langganan = await Repositori.langganan();
        final ebook = await Repositori.ebook();
        return (langganan, ebook);
      },
      rangka: _RangkaPustaka(padding: padding),
      kosong: (data) => data.$1.bolehUnduhResep && data.$2.isEmpty,
      saatKosong: ListView(
        padding: padding,
        children: const [
          KepalaHalaman(judul: 'Pustaka'),
          Keadaan(
            ikon: Icons.auto_stories_outlined,
            judul: 'Pustaka masih kosong',
            keterangan:
                'Belum ada konten yang diterbitkan. Pustaka ini bertambah '
                'dari waktu ke waktu — tidak perlu melakukan apa pun.',
          ),
        ],
      ),
      isi: (context, data) {
        final (langganan, ebook) = data;
        return RefreshIndicator(
          onRefresh: () =>
              _kunci.currentState?.muatUlangTunggu() ?? Future<void>.value(),
          child: _DaftarPustaka(
            ebook: ebook,
            terkunci: !langganan.bolehUnduhResep,
            padding: padding,
            onKeAkun: onKeAkun,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Daftar & filter jenis konten
// ---------------------------------------------------------------------------

class _DaftarPustaka extends StatefulWidget {
  const _DaftarPustaka({
    required this.ebook,
    required this.terkunci,
    required this.padding,
    this.onKeAkun,
  });

  final List<Ebook> ebook;
  final bool terkunci;
  final EdgeInsets padding;
  final VoidCallback? onKeAkun;

  @override
  State<_DaftarPustaka> createState() => _DaftarPustakaState();
}

class _DaftarPustakaState extends State<_DaftarPustaka> {
  final _kendaliCari = TextEditingController();
  String _cari = '';
  JenisKonten? _jenis;

  @override
  void dispose() {
    _kendaliCari.dispose();
    super.dispose();
  }

  List<Ebook> _saring(List<Ebook> daftar) {
    final hasil = _jenis == null
        ? daftar
        : daftar.where((e) => e.jenis == _jenis).toList();

    final kata = _cari.trim().toLowerCase();
    if (kata.isEmpty) return hasil;

    return hasil
        .where(
          (e) =>
              e.judul.toLowerCase().contains(kata) ||
              e.deskripsi.toLowerCase().contains(kata),
        )
        .toList();
  }

  int _jumlah(JenisKonten? jenis) => jenis == null
      ? widget.ebook.length
      : widget.ebook.where((e) => e.jenis == jenis).length;

  void _aturUlang() {
    _kendaliCari.clear();
    setState(() {
      _cari = '';
      _jenis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final terpilih = _saring(widget.ebook);
    final adaSaringan = _cari.trim().isNotEmpty || _jenis != null;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            widget.padding.left,
            widget.padding.top,
            widget.padding.right,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KepalaHalaman(
                  judul: 'Pustaka',
                  keterangan: widget.terkunci
                      ? 'Perpanjang langganan untuk membuka Pustaka.'
                      : '${widget.ebook.length} konten siap dibuka.',
                ),
                if (!widget.terkunci) ...[
                  const SizedBox(height: Jarak.xs),
                  TextField(
                    controller: _kendaliCari,
                    onChanged: (v) => setState(() => _cari = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari judul atau deskripsi…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _cari.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _kendaliCari.clear();
                                setState(() => _cari = '');
                              },
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Hapus pencarian',
                            ),
                    ),
                  ),
                  const SizedBox(height: Jarak.xs2),
                  _PilJenis(
                    terpilih: _jenis,
                    jumlah: {
                      null: _jumlah(null),
                      JenisKonten.resep: _jumlah(JenisKonten.resep),
                      JenisKonten.prompt: _jumlah(JenisKonten.prompt),
                    },
                    onPilih: (jenis) => setState(() => _jenis = jenis),
                  ),
                  // Ruang napas antara baris filter dan grid di bawahnya —
                  // tanpa ini kartu pertama menempel pada pill terlalu rapat.
                  const SizedBox(height: Jarak.sm),
                ],
              ],
            ),
          ),
        ),
        if (widget.terkunci)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: widget.padding.left),
            sliver: SliverToBoxAdapter(
              child: Keadaan(
                ikon: Icons.lock_rounded,
                judul: 'Pustaka Terkunci',
                keterangan:
                    'Resep dan prompt eksklusif hanya tersedia pada paket '
                    'Langganan (Berbayar). Akun Trial dan Gratis dapat '
                    'memperpanjang paket untuk membuka seluruh Pustaka.',
                labelAksi: 'Buka Akses Paket Langganan',
                onAksi: () => ModalFiturTerkunci.tampilkan(
                  context,
                  jenis: JenisFiturTerkunci.resep,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              widget.padding.left,
              0,
              widget.padding.right,
              widget.padding.bottom,
            ),
            sliver: terpilih.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Keadaan(
                      ikon: Icons.search_off_rounded,
                      judul: 'Tidak ada yang cocok',
                      keterangan: adaSaringan
                          ? 'Tidak ada konten yang memuat kata kunci atau '
                                'jenis yang kamu cari.'
                          : 'Belum ada konten di Pustaka.',
                      labelAksi: adaSaringan ? 'Atur ulang' : null,
                      onAksi: adaSaringan ? _aturUlang : null,
                    ),
                  )
                : SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisSpacing: Jarak.xs,
                      crossAxisSpacing: Jarak.xs,
                      mainAxisExtent: 208,
                    ),
                    itemCount: terpilih.length,
                    itemBuilder: (context, i) => _KartuKonten(ebook: terpilih[i]),
                  ),
          ),
      ],
    );
  }
}

class _PilJenis extends StatelessWidget {
  const _PilJenis({
    required this.terpilih,
    required this.jumlah,
    required this.onPilih,
  });

  final JenisKonten? terpilih;

  /// Jumlah konten per jenis; kunci null = "Semua".
  final Map<JenisKonten?, int> jumlah;
  final ValueChanged<JenisKonten?> onPilih;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _Pil(
            label: 'Semua',
            ikon: Icons.grid_view_rounded,
            jumlah: jumlah[null] ?? 0,
            aktif: terpilih == null,
            onTekan: () => onPilih(null),
          ),
          const SizedBox(width: Jarak.xs2),
          _Pil(
            label: 'Resep',
            ikon: Icons.restaurant_menu_rounded,
            jumlah: jumlah[JenisKonten.resep] ?? 0,
            aktif: terpilih == JenisKonten.resep,
            onTekan: () => onPilih(JenisKonten.resep),
          ),
          const SizedBox(width: Jarak.xs2),
          _Pil(
            label: 'Prompt',
            ikon: Icons.auto_awesome_rounded,
            jumlah: jumlah[JenisKonten.prompt] ?? 0,
            aktif: terpilih == JenisKonten.prompt,
            onTekan: () => onPilih(JenisKonten.prompt),
          ),
        ],
      ),
    );
  }
}

class _Pil extends StatelessWidget {
  const _Pil({
    required this.label,
    required this.ikon,
    required this.jumlah,
    required this.aktif,
    required this.onTekan,
  });

  final String label;
  final IconData ikon;
  final int jumlah;
  final bool aktif;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;

    return Semantics(
      button: true,
      selected: aktif,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
        child: AnimatedContainer(
          duration: Gerak.sedang,
          curve: Gerak.keluar,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: aktif ? a.fokus : context.warna.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(Lengkung.bulat),
            border: Border.all(color: aktif ? a.fokus : context.warna.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ikon,
                size: 18,
                color: aktif ? a.atasFokus : context.warna.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.teks.labelLarge?.copyWith(
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                  color: aktif ? a.atasFokus : context.warna.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: aktif
                      ? a.atasFokus.withValues(alpha: 0.18)
                      : context.warna.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Lengkung.bulat),
                ),
                child: Text(
                  '$jumlah',
                  style: context.teks.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: aktif
                        ? a.atasFokus
                        : context.warna.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rangka (loading) Pustaka
// ---------------------------------------------------------------------------

/// Rangka saat menunggu data — menggantikan pemintal kosong.
///
/// Memakai grid kartu yang geometrinya sama dengan kartu konten sungguhan,
/// jadi tata letak tidak melompat saat data tiba, plus ilustrasi vektor
/// agar menunggu tidak terasa seperti layar yang belum rampung.
class _RangkaPustaka extends StatelessWidget {
  const _RangkaPustaka({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Meniru struktur isi yang sesungguhnya (header + cari + pill + grid)
    // supaya saat data tiba tata letak tidak melompat dan tidak terasa seperti
    // layar yang berbeda.
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KepalaHalaman(judul: 'Pustaka'),
                const SizedBox(height: Jarak.xs),
                const Rangka(tinggi: 48, radius: Lengkung.kontrol),
                const SizedBox(height: Jarak.xs2),
                const Row(
                  children: [
                    Rangka(lebar: 104, tinggi: 38, radius: Lengkung.bulat),
                    SizedBox(width: Jarak.xs2),
                    Rangka(lebar: 104, tinggi: 38, radius: Lengkung.bulat),
                    SizedBox(width: Jarak.xs2),
                    Rangka(lebar: 108, tinggi: 38, radius: Lengkung.bulat),
                  ],
                ),
                const SizedBox(height: Jarak.sm),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            0,
            padding.right,
            padding.bottom,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisSpacing: Jarak.xs,
              crossAxisSpacing: Jarak.xs,
              mainAxisExtent: 208,
            ),
            itemCount: 6,
            itemBuilder: (context, i) => const _RangkaKartuPustaka(),
          ),
        ),
      ],
    );
  }
}

class _RangkaKartuPustaka extends StatelessWidget {
  const _RangkaKartuPustaka();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Rangka(
              lebar: 92,
              tinggi: double.infinity,
              radius: Lengkung.kecil,
            ),
            const SizedBox(width: Jarak.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Rangka(lebar: 150, tinggi: 12),
                  SizedBox(height: 3),
                  Rangka(lebar: 200, tinggi: 10),
                  SizedBox(height: Jarak.xs2),
                  Expanded(child: Rangka(tinggi: double.infinity)),
                  SizedBox(height: Jarak.xs2),
                  Rangka(lebar: 72, tinggi: 12),
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
// Kartu konten
// ---------------------------------------------------------------------------

final _gayaTombol = ButtonStyle(
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: Jarak.xs),
  ),
  minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  textStyle: const WidgetStatePropertyAll(
    TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  ),
);

class _KartuKonten extends StatelessWidget {
  const _KartuKonten({required this.ebook});

  final Ebook ebook;

  Future<void> _buka(BuildContext context) async {
    // Akses tanpa langganan → jangan coba unduh; langsung arahkan ke pembayaran.
    if (!ebook.bolehUnduh) {
      await ModalFiturTerkunci.tampilkan(
        context,
        jenis: JenisFiturTerkunci.resep,
      );
      return;
    }

    try {
      final url = await Repositori.bukaEbook(ebook.id);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BacaScreen(judul: ebook.judul, url: url),
        ),
      );
    } on GagalMuat catch (e) {
      if (!context.mounted) return;

      // Kalau server menolak karena langganan, munculkan dialog upgrade —
      // bukan toast panjang yang menyalahkan pengguna.
      if (_terkunci(e.pesan)) {
        await ModalFiturTerkunci.tampilkan(
          context,
          jenis: JenisFiturTerkunci.resep,
        );
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.pesan)));
    }
  }

  static bool _terkunci(String pesan) {
    final teks = pesan.toLowerCase();
    return teks.contains('langganan') ||
        teks.contains('paket') ||
        teks.contains('perpanjang');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _buka(context),
        borderRadius: BorderRadius.circular(Lengkung.panel),
        child: Padding(
          padding: const EdgeInsets.all(Jarak.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 92,
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
                    const SizedBox(height: 3),
                    Text(
                      '${ebook.labelKategori} · ${ebook.jumlahHalaman} hal · '
                      '${ebook.ukuranMb.toStringAsFixed(1)} MB',
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Jarak.xs2),
                    Expanded(
                      child: Text(
                        ebook.deskripsi,
                        style: context.teks.bodySmall?.copyWith(
                          color: context.warna.onSurfaceVariant,
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs2),
                    SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: () => _buka(context),
                        icon: const Icon(
                          Icons.menu_book_outlined,
                          size: 17,
                        ),
                        label: const Text('Buka'),
                        style: _gayaTombol,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
