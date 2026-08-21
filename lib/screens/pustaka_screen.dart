import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/bingkai.dart';
import '../widgets/sampul_ebook.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/modal_fitur_terkunci.dart';
import '../widgets/rangka.dart';
import 'baca_screen.dart';

/// Pustaka konten: resep dan prompt berbentuk PDF.
///
/// Dua macam konten, perlakuan sama: keduanya bisa dilihat langsung di
/// aplikasi tanpa diunduh. Seluruh konten terbit terbuka untuk langganan yang
/// masih berjalan (PRD §4.3). Kalau langganan mati, Pustaka terkunci.
class PustakaScreen extends StatelessWidget {
  const PustakaScreen({super.key, this.onKeAkun});

  final VoidCallback? onKeAkun;

  @override
  Widget build(BuildContext context) {
    final padding = paddingHalaman(context);

    return Bingkai<(Langganan, List<Ebook>)>(
      ambil: () async {
        final l = await Repositori.langganan();
        final e = await Repositori.ebook();
        return (l, e);
      },
      rangka: ListView(
        padding: padding,
        children: const [
          KepalaHalaman(judul: 'Pustaka'),
          RangkaDaftar(baris: 4, tinggiBaris: 100),
        ],
      ),
      kosong: (d) => d.$1.bolehUnduhResep && d.$2.isEmpty,
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
        final terkunci = !langganan.bolehUnduhResep;

        return _Daftar(
          ebook: ebook,
          terkunci: terkunci,
          padding: padding,
          onKeAkun: onKeAkun,
        );
      },
    );
  }
}

class _Daftar extends StatefulWidget {
  const _Daftar({
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
  State<_Daftar> createState() => _DaftarState();
}

class _DaftarState extends State<_Daftar> {
  JenisKonten? _jenis;

  @override
  Widget build(BuildContext context) {
    final terpilih = _jenis == null
        ? widget.ebook
        : widget.ebook
              .where((e) => e.jenis == _jenis)
              .toList();

    return CustomScrollView(
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
                const SizedBox(height: Jarak.xs),
                if (!widget.terkunci) _TabJenis(terpilih: _jenis, onPilih: _aturJenis),
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
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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

  void _aturJenis(JenisKonten? jenis) => setState(() => _jenis = jenis);
}

class _TabJenis extends StatelessWidget {
  const _TabJenis({required this.terpilih, required this.onPilih});

  final JenisKonten? terpilih;
  final ValueChanged<JenisKonten?> onPilih;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: terpilih == null,
            onSelected: (_) => onPilih(null),
          ),
          const SizedBox(width: Jarak.xs2),
          ChoiceChip(
            label: const Text('Resep'),
            selected: terpilih == JenisKonten.resep,
            onSelected: (_) => onPilih(JenisKonten.resep),
          ),
          const SizedBox(width: Jarak.xs2),
          ChoiceChip(
            label: const Text('Prompt'),
            selected: terpilih == JenisKonten.prompt,
            onSelected: (_) => onPilih(JenisKonten.prompt),
          ),
        ],
      ),
    );
  }
}

final _gaya = ButtonStyle(
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
                        style: _gaya,
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
