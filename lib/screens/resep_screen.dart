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
import '../widgets/rangka.dart';

/// Katalog ebook resep.
///
/// PRD §4.3: **seluruh ebook terbit terbuka untuk langganan yang masih
/// berjalan.** Tidak ada pemberian akses per-ebook, tidak ada ebook gratis —
/// dan justru kesederhanaan itu yang membuatnya jadi alasan berlangganan.
///
/// Kalau langganan mati, katalognya terkunci tapi Riwayat dan Laporan tetap
/// terbuka. Data penjualan milik pemilik toko; menyanderanya untuk memaksa
/// perpanjangan adalah hal yang berbeda sama sekali dari menahan bonus.
class ResepScreen extends StatelessWidget {
  const ResepScreen({super.key, this.onKeAkun});

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
          KepalaHalaman(judul: 'Resep'),
          RangkaDaftar(baris: 4, tinggiBaris: 100),
        ],
      ),
      kosong: (d) => d.$1.bolehUnduhResep && d.$2.isEmpty,
      saatKosong: ListView(
        padding: padding,
        children: const [
          KepalaHalaman(judul: 'Resep'),
          Keadaan(
            ikon: Icons.menu_book_outlined,
            judul: 'Katalog masih kosong',
            keterangan:
                'Belum ada ebook yang diterbitkan. Katalog ini bertambah '
                'dari waktu ke waktu — tidak perlu melakukan apa pun.',
          ),
        ],
      ),
      isi: (context, data) {
        final (langganan, ebook) = data;
        final terkunci = !langganan.bolehUnduhResep;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                padding.top,
                padding.right,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: KepalaHalaman(
                  judul: 'Resep',
                  keterangan: terkunci
                      ? 'Perpanjang langganan untuk membuka katalog.'
                      : '${ebook.length} ebook siap diunduh.',
                ),
              ),
            ),
            if (terkunci)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: padding.left),
                sliver: SliverToBoxAdapter(
                  child: Keadaan(
                    ikon: Icons.lock_outline,
                    judul: 'Katalog terkunci',
                    keterangan:
                        'Ebook resep hanya bisa diunduh selama langganan '
                        'aktif. Riwayat dan laporan tetap bisa Anda buka.',
                    labelAksi: 'Lihat langganan',
                    onAksi: onKeAkun,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  0,
                  padding.right,
                  padding.bottom,
                ),
                // 420, bukan 330: kartunya bersusun mendatar (sampul di kiri,
                // teks di kanan), jadi kolom kedua hanya boleh muncul kalau
                // sisa lebar untuk teksnya benar-benar cukup.
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisSpacing: Jarak.xs,
                    crossAxisSpacing: Jarak.xs,
                    mainAxisExtent: 208,
                  ),
                  itemCount: ebook.length,
                  itemBuilder: (context, i) => _KartuEbook(ebook: ebook[i]),
                ),
              ),
          ],
        );
      },
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

void _pesan(BuildContext context, String apa) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$apa menyusul.')));
}

class _KartuEbook extends StatelessWidget {
  const _KartuEbook({required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Detail "${ebook.judul}" menyusul.')),
          ),
        borderRadius: BorderRadius.circular(Lengkung.panel),
        child: Padding(
          padding: const EdgeInsets.all(Jarak.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sampul tipografis, bukan petak foto kosong. Enam kotak abu yang
              // identik adalah alasan daftar ini terasa mati sebelumnya.
              SizedBox(
                width: 92,
                child: SampulEbook(
                  judul: ebook.judul,
                  kategori: ebook.kategori,
                  sudahDiunduh: ebook.sudahDiunduh,
                ),
              ),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul lebih dulu, kategori turun jadi keterangan. Nama
                    // buku yang dicari orang, bukan rak tempat ia berdiri.
                    Text(
                      ebook.judul,
                      style: context.teks.titleSmall?.copyWith(height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${ebook.kategori} · ${ebook.jumlahHalaman} hal · '
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
                      child: ebook.sudahDiunduh
                          ? OutlinedButton.icon(
                              onPressed: () => _pesan(context, 'Buka bacaan'),
                              icon: const Icon(
                                Icons.menu_book_outlined,
                                size: 17,
                              ),
                              label: const Text('Baca'),
                              style: _gaya,
                            )
                          : FilledButton.icon(
                              onPressed: () => _pesan(context, 'Unduhan'),
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 17,
                              ),
                              label: const Text('Unduh'),
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
