import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/app_shell.dart';
import '../widgets/bingkai.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/rangka.dart';
import '../widgets/sampul_ebook.dart';
import 'baca_screen.dart';
import 'status_bayar_screen.dart';

/// Pustaka konten: resep dan prompt berbentuk PDF.
///
/// Katalog terbuka untuk SEMUA akun. Akses per-konten diatur oleh status
/// dari server: TERBUKA (sudah dibuka), BISA_KLAIM (jatah langganan tersedia),
/// atau TERKUNCI (perlu beli satuan).
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
      bentukGalat: BentukGalat.halaman,
      pembungkusGalat: (galat) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              0,
            ),
            child: const KepalaHalaman(judul: 'Pustaka'),
          ),
          Expanded(child: galat),
        ],
      ),
      ambil: () async {
        final langganan = await Repositori.langganan();
        final ebook = await Repositori.ebook();
        return (langganan, ebook);
      },
      rangka: _RangkaPustaka(padding: padding),
      kosong: (data) => data.$2.isEmpty,
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
        final (_, ebook) = data;
        return RefreshIndicator(
          onRefresh: () =>
              _kunci.currentState?.muatUlangTunggu() ?? Future<void>.value(),
          child: _DaftarPustaka(
            ebook: ebook,
            padding: padding,
            onRefresh: () =>
                _kunci.currentState?.muatUlangTunggu() ?? Future<void>.value(),
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
    required this.padding,
    this.onRefresh,
  });

  final List<Ebook> ebook;
  final EdgeInsets padding;
  final VoidCallback? onRefresh;

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

  /// Hitung ringkasan status akses untuk header.
  int get _terbuka =>
      widget.ebook.where((e) => e.statusAkses == 'TERBUKA').length;
  int get _bisaKlaim =>
      widget.ebook.where((e) => e.statusAkses == 'BISA_KLAIM').length;
  int get _terkunci =>
      widget.ebook.where((e) => e.statusAkses == 'TERKUNCI').length;

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
                  keterangan: '${widget.ebook.length} konten tersedia.',
                ),
                if (_terbuka > 0 || _bisaKlaim > 0) ...[
                  const SizedBox(height: Jarak.xs2),
                  _RingkasanAkses(
                    terbuka: _terbuka,
                    bisaKlaim: _bisaKlaim,
                    terkunci: _terkunci,
                  ),
                ],
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
                const SizedBox(height: Jarak.sm),
              ],
            ),
          ),
        ),
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
                  itemBuilder: (context, i) => _KartuKonten(
                    // Kartu ini menyimpan status `_memproses`. Daftarnya
                    // tersaring, jadi tanpa kunci posisi kartu bisa berpindah
                    // ke konten lain dan penjaga tap-nya ikut salah sasaran.
                    key: ValueKey(terpilih[i].id),
                    ebook: terpilih[i],
                    onBerubah: widget.onRefresh,
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ringkasan akses di header
// ---------------------------------------------------------------------------

class _RingkasanAkses extends StatelessWidget {
  const _RingkasanAkses({
    required this.terbuka,
    required this.bisaKlaim,
    required this.terkunci,
  });

  final int terbuka;
  final int bisaKlaim;
  final int terkunci;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Jarak.xs2,
      runSpacing: Jarak.xs2,
      children: [
        if (terbuka > 0) _CipAkses(jumlah: terbuka, label: 'Terbuka', warna: context.aksen.sukses),
        if (bisaKlaim > 0) _CipAkses(jumlah: bisaKlaim, label: 'Bisa Klaim', warna: context.aksen.info),
        if (terkunci > 0) _CipAkses(jumlah: terkunci, label: 'Terkunci', warna: context.warna.onSurfaceVariant),
      ],
    );
  }
}

class _CipAkses extends StatelessWidget {
  const _CipAkses({
    required this.jumlah,
    required this.label,
    required this.warna,
  });

  final int jumlah;
  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Lengkung.bulat),
        border: Border.all(color: warna.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$jumlah $label',
            style: context.teks.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter jenis konten
// ---------------------------------------------------------------------------

class _PilJenis extends StatelessWidget {
  const _PilJenis({
    required this.terpilih,
    required this.jumlah,
    required this.onPilih,
  });

  final JenisKonten? terpilih;
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

class _RangkaPustaka extends StatelessWidget {
  const _RangkaPustaka({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
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

class _KartuKonten extends StatefulWidget {
  const _KartuKonten({super.key, required this.ebook, this.onBerubah});

  final Ebook ebook;
  final VoidCallback? onBerubah;

  @override
  State<_KartuKonten> createState() => _KartuKontenState();
}

class _KartuKontenState extends State<_KartuKonten> {
  /// Penjaga anti-tap-ganda selagi tagihan sedang dibuat.
  bool _memproses = false;

  Ebook get ebook => widget.ebook;

  Future<void> _buka(BuildContext context) async {
    // Sudah terbuka — langsung baca.
    if (ebook.terbuka || ebook.bolehUnduh) {
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.pesan)));
      }
      return;
    }

    // Bisa klaim — tampilkan dialog konfirmasi.
    if (ebook.statusAkses == 'BISA_KLAIM') {
      await _tampilkanDialogKlaim(context);
      return;
    }

    // Terkunci — tampilkan opsi beli atau langganan.
    await _tampilkanDialogBeli(context);
  }

  Future<void> _tampilkanDialogKlaim(BuildContext context) async {
    final klaim = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LembarKlaim(ebook: ebook),
    );

    if (klaim == true && context.mounted) {
      try {
        final pesan = await Repositori.klaimPustaka(ebook.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(pesan)));
        widget.onBerubah?.call();
      } on GagalMuat catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.pesan)));
      }
    }
  }

  /// Tawarkan beli satuan, lalu terbitkan tagihannya dan buka layar bayar.
  ///
  /// Panggilan jaringan ada di sini, bukan di dalam lembar: lembarnya sudah
  /// ditutup sebelum tagihan selesai dibuat, jadi `context`-nya sudah mati dan
  /// SnackBar-nya tidak akan pernah muncul. `context` milik kartu ini tetap
  /// hidup selama prosesnya.
  Future<void> _tampilkanDialogBeli(BuildContext context) async {
    if (_memproses) return;

    final jadiBeli = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LembarBeli(ebook: ebook),
    );

    if (jadiBeli != true || !context.mounted) return;

    setState(() => _memproses = true);

    try {
      final tagihan = await Repositori.beliPustaka(
        ebookId: ebook.id,
        saluran: SaluranBayar.qris,
      );
      if (!context.mounted) return;

      // `push`, bukan `pushReplacement`: setelah membayar pembeli harus
      // kembali ke katalog untuk membaca konten yang barusan dibuka.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StatusBayarScreen(tagihan: tagihan),
        ),
      );
    } on GagalMuat catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.pesan)));
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
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
                    _TombolAksiKonten(
                      ebook: ebook,
                      onTap: () => _buka(context),
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

/// Tombol aksi di kartu — berubah warna & label sesuai status akses.
class _TombolAksiKonten extends StatelessWidget {
  const _TombolAksiKonten({required this.ebook, required this.onTap});

  final Ebook ebook;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final terbuka = ebook.terbuka || ebook.bolehUnduh;
    final bisaKlaim = ebook.statusAkses == 'BISA_KLAIM';

    final IconData ikon;
    final String label;
    final Color? warna;

    if (terbuka) {
      ikon = Icons.menu_book_outlined;
      label = 'Buka';
      warna = null; // default primary
    } else if (bisaKlaim) {
      ikon = Icons.card_giftcard_rounded;
      label = 'Klaim Gratis';
      warna = null; // primary
    } else {
      ikon = Icons.lock_outline_rounded;
      label = 'Rp ${rupiah(ebook.harga).replaceAll('Rp ', '')}';
      warna = context.warna.onSurfaceVariant;
    }

    return SizedBox(
      height: 36,
      child: terbuka || bisaKlaim
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(ikon, size: 17),
              label: Text(label),
              style: _gayaTombol,
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(ikon, size: 16),
              label: Text(label),
              style: _gayaTombol.copyWith(
                foregroundColor: WidgetStatePropertyAll(warna),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lembar Klaim
// ---------------------------------------------------------------------------

class _LembarKlaim extends StatelessWidget {
  const _LembarKlaim({required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    final labelJenis =
        ebook.jenis == JenisKonten.resep ? 'Resep' : 'Prompt';

    return Container(
      decoration: BoxDecoration(
        color: context.warna.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Lengkung.panel),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Jarak.md,
        Jarak.sm,
        Jarak.md,
        MediaQuery.of(context).padding.bottom + Jarak.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: Jarak.md),
              decoration: BoxDecoration(
                color: context.warna.outlineVariant,
                borderRadius: BorderRadius.circular(Lengkung.bulat),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.aksen.info.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 24,
              color: context.aksen.info,
            ),
          ),
          const SizedBox(height: Jarak.sm),
          Text(
            'Klaim Gratis — Jatah $labelJenis',
            style: context.teks.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Jarak.xs2),
          Text(
            'Kamu memiliki 1 jatah klaim $labelJenis gratis dari '
            'langganan aktif. Konten yang diklaim akan terbuka '
            'permanen untuk tokomu.',
            style: context.teks.bodyMedium?.copyWith(
              color: context.warna.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: Jarak.xs2),
          Container(
            padding: const EdgeInsets.all(Jarak.xs),
            decoration: BoxDecoration(
              color: context.warna.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(Lengkung.kecil),
              border: Border.all(color: context.warna.outline),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: SampulEbook(
                    judul: ebook.judul,
                    kategori: ebook.labelKategori,
                    jenis: ebook.jenis,
                    coverUrl: ebook.coverUrl,
                  ),
                ),
                const SizedBox(width: Jarak.xs),
                Expanded(
                  child: Text(
                    ebook.judul,
                    style: context.teks.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Jarak.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Klaim Sekarang'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lembar Beli Satuan
// ---------------------------------------------------------------------------

class _LembarBeli extends StatelessWidget {
  const _LembarBeli({required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    final labelJenis =
        ebook.jenis == JenisKonten.resep ? 'Resep' : 'Prompt';

    return Container(
      decoration: BoxDecoration(
        color: context.warna.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Lengkung.panel),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Jarak.md,
        Jarak.sm,
        Jarak.md,
        MediaQuery.of(context).padding.bottom + Jarak.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: Jarak.md),
              decoration: BoxDecoration(
                color: context.warna.outlineVariant,
                borderRadius: BorderRadius.circular(Lengkung.bulat),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.warna.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.lock_outline_rounded,
              size: 24,
              color: context.warna.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Jarak.sm),
          Text(
            'Beli Akses $labelJenis',
            style: context.teks.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Jarak.xs2),
          Text(
            'Beli akses permanen ke konten ini seharga '
            '${rupiah(ebook.harga)}. Pembayaran melalui QRIS.',
            style: context.teks.bodyMedium?.copyWith(
              color: context.warna.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: Jarak.xs2),
          Container(
            padding: const EdgeInsets.all(Jarak.xs),
            decoration: BoxDecoration(
              color: context.warna.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(Lengkung.kecil),
              border: Border.all(color: context.warna.outline),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
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
                        style: context.teks.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        rupiah(ebook.harga),
                        style: context.teks.labelLarge?.copyWith(
                          color: context.aksen.sukses,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Jarak.xs2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Jarak.xs,
              vertical: Jarak.xs2,
            ),
            decoration: BoxDecoration(
              color: context.aksen.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Lengkung.kecil),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: context.aksen.info),
                const SizedBox(width: Jarak.xs2),
                Expanded(
                  child: Text(
                    'Atau perpanjang langganan untuk jatah 1 $labelJenis gratis.',
                    style: context.teks.bodySmall?.copyWith(
                      color: context.aksen.info,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Jarak.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              // Pemilih murni — persis `_LembarKlaim`. Tagihannya diterbitkan
              // pemanggil setelah lembar ini tertutup, supaya tidak ada
              // panggilan jaringan yang menahan lembar tetap terbuka.
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Beli Akses — ${rupiah(ebook.harga)}'),
            ),
          ),
          const SizedBox(height: Jarak.xs),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ),
        ],
      ),
    );
  }
}
