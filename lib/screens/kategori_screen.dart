import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/bingkai.dart';
import '../widgets/ikon_kotak.dart';
import '../widgets/isian_uang.dart';
import '../widgets/kartu.dart';
import '../widgets/keadaan.dart';
import '../widgets/rangka.dart';
import '../widgets/tombol_pil.dart';

/// Kelola kategori produk.
///
/// Kategori terlihat seperti master data yang membosankan, padahal ia satu-
/// satunya hal di aplikasi ini yang **urutannya dipakai di tempat lain**:
/// baris chip di kasir dan urutan bagian di layar Produk mengikuti persis
/// urutan di sini. Karena itu layar ini bisa digeser-urutkan, bukan cuma
/// ditambah dan dihapus — kategori yang paling sering dijual harus bisa
/// ditaruh di jempol kasir.
class KategoriScreen extends StatelessWidget {
  const KategoriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori produk')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Bingkai<(List<Kategori>, List<Produk>)>(
              ambil: () async {
                final k = await Repositori.kategori();
                final p = await Repositori.produk();
                return (k, p);
              },
              rangka: const Padding(
                padding: EdgeInsets.all(Jarak.sm),
                child: RangkaDaftar(baris: 4),
              ),
              kosong: (d) => d.$1.isEmpty,
              saatKosong: const _Kosong(),
              isi: (context, data) => _Isi(kategori: data.$1, produk: data.$2),
            ),
          ),
        ),
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Jarak.sm),
      child: Keadaan(
        ikon: Icons.category_outlined,
        judul: 'Belum ada kategori',
        keterangan:
            'Kategori memisahkan menu di kasir supaya tidak semua barang '
            'tampil sekaligus. Dua atau tiga sudah cukup untuk mulai.',
        labelAksi: 'Tambah kategori',
        onAksi: () => suntingKategori(context, kategori: null),
      ),
    );
  }
}

class _Isi extends StatefulWidget {
  const _Isi({required this.kategori, required this.produk});

  final List<Kategori> kategori;
  final List<Produk> produk;

  @override
  State<_Isi> createState() => _IsiState();
}

class _IsiState extends State<_Isi> {
  /// Urutan dipegang di sini, bukan dibaca ulang dari repositori tiap bingkai.
  ///
  /// Baris yang dilepas harus berhenti di tempat ia dilepas — kalau daftarnya
  /// datang lagi dari sumber setelah setiap geseran, baris itu akan berkedip
  /// balik ke posisi lama sepersekian detik. Kedipan itu yang membuat orang
  /// mengira geserannya gagal, lalu mengulanginya.
  late List<Kategori> _urutan = List.of(widget.kategori);

  @override
  void didUpdateWidget(_Isi lama) {
    super.didUpdateWidget(lama);
    // Menambah atau menghapus kategori memuat ulang bingkainya. Di situ
    // daftarnya memang harus diambil ulang — yang tidak boleh diambil ulang
    // cuma setelah geseran.
    if (widget.kategori != lama.kategori) _urutan = List.of(widget.kategori);
  }

  int _jumlahProduk(String kategoriId) =>
      widget.produk.where((p) => p.kategoriId == kategoriId).length;

  /// Dipasang ke `onReorderItem`, bukan `onReorder` yang sudah usang.
  ///
  /// Bedanya bukan sekadar nama: `onReorderItem` sudah mengoreksi sendiri
  /// pergeseran indeks setelah elemennya diangkat, jadi tidak perlu lagi
  /// `ke > dari ? ke - 1 : ke` yang dulu wajib ditulis tangan — dan yang
  /// selalu jadi tempat pindah-ke-bawah meleset satu posisi.
  Future<void> _geser(int dari, int ke) async {
    setState(() => _urutan.insert(ke, _urutan.removeAt(dari)));
    await Repositori.urutkanKategori(_urutan);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(
              Jarak.sm,
              Jarak.xs,
              Jarak.sm,
              Jarak.sm,
            ),
            header: const _Catatan(),
            itemCount: _urutan.length,
            onReorderItem: _geser,
            proxyDecorator: (anak, _, animasi) => Material(
              color: Colors.transparent,
              elevation: 6 * animasi.value,
              borderRadius: BorderRadius.circular(Lengkung.kontrol),
              child: anak,
            ),
            itemBuilder: (context, i) {
              final k = _urutan[i];
              return Padding(
                // Kunci wajib dan wajib stabil: tanpa itu Flutter kehilangan
                // jejak baris mana yang sedang diangkat.
                key: ValueKey(k.id),
                padding: const EdgeInsets.only(bottom: Jarak.xs2),
                child: _BarisKategori(
                  kategori: k,
                  indeks: i,
                  jumlahProduk: _jumlahProduk(k.id),
                  bolehHapus: _urutan.length > 1,
                  lainnya: [
                    for (final l in _urutan)
                      if (l.id != k.id) l,
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
          child: TombolPil(
            label: 'Tambah kategori',
            onTekan: () => suntingKategori(context, kategori: null),
          ),
        ),
      ],
    );
  }
}

class _BarisKategori extends StatelessWidget {
  const _BarisKategori({
    required this.kategori,
    required this.indeks,
    required this.jumlahProduk,
    required this.bolehHapus,
    required this.lainnya,
  });

  final Kategori kategori;
  final int indeks;
  final int jumlahProduk;
  final bool bolehHapus;

  /// Kategori tujuan yang tersedia saat yang ini dihapus.
  final List<Kategori> lainnya;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => suntingKategori(context, kategori: kategori),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Jarak.xs,
            vertical: Jarak.xs,
          ),
          child: Row(
            children: [
              IkonKotak(kategori.ikon, ukuran: 40),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kategori.nama,
                      style: context.teks.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      jumlahProduk == 0
                          ? 'Belum ada produk'
                          : '$jumlahProduk produk',
                      style: context.teks.bodySmall?.copyWith(
                        color: context.warna.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: bolehHapus
                    ? () => _hapus(
                        context,
                        kategori: kategori,
                        jumlahProduk: jumlahProduk,
                        lainnya: lainnya,
                      )
                    : null,
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: bolehHapus
                    ? 'Hapus ${kategori.nama}'
                    : 'Kategori terakhir tidak bisa dihapus',
              ),
              // Pegangan geser, bukan seluruh baris: baris yang bisa digeser
              // seluruhnya membuat gulir daftar berubah jadi memindahkan
              // kategori setiap kali jari sedikit menyamping.
              ReorderableDragStartListener(
                index: indeks,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Jarak.xs3),
                  child: Icon(
                    Icons.drag_handle,
                    size: 22,
                    color: context.warna.onSurfaceVariant,
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

class _Catatan extends StatelessWidget {
  const _Catatan();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Jarak.xs),
      child: Container(
        padding: const EdgeInsets.all(Jarak.xs),
        decoration: BoxDecoration(
          color: context.aksen.kartuAlt,
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          border: Border.all(color: context.warna.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.swap_vert,
              size: 20,
              color: context.warna.onSurfaceVariant,
            ),
            const SizedBox(width: Jarak.xs2),
            Expanded(
              child: Text(
                'Urutan di sini adalah urutan chip di kasir. Geser pegangan '
                'di kanan untuk menaruh yang paling sering dijual di depan.',
                style: context.teks.bodySmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tambah / ubah
// ---------------------------------------------------------------------------

/// Lembar tambah-atau-ubah. `kategori` null berarti kategori baru.
///
/// Mengembalikan kategori yang tersimpan, atau null kalau lembarnya ditutup
/// tanpa menyimpan. Nilai baliknya dipakai formulir produk: kategori yang baru
/// dibuat dari sana harus langsung terpilih, bukan menyisakan pekerjaan
/// "sekarang cari lagi yang tadi kamu buat".
Future<Kategori?> suntingKategori(
  BuildContext context, {
  required Kategori? kategori,
}) {
  return showModalBottomSheet<Kategori>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _LembarKategori(awal: kategori),
  );
}

class _LembarKategori extends StatefulWidget {
  const _LembarKategori({required this.awal});

  final Kategori? awal;

  @override
  State<_LembarKategori> createState() => _LembarKategoriState();
}

class _LembarKategoriState extends State<_LembarKategori> {
  late final TextEditingController _nama = TextEditingController(
    text: widget.awal?.nama ?? '',
  );
  late IconData _ikon = widget.awal?.ikon ?? ikonKategoriPilihan.first;

  bool _tersentuh = false;
  bool _menyimpan = false;
  String? _galat;

  bool get _ubah => widget.awal != null;
  bool get _kurang => _nama.text.trim().length < 2;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() => _tersentuh = true);
    if (_kurang) return;

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      final tersimpan = await Repositori.simpanKategori(
        widget.awal?.salin(nama: _nama.text.trim(), ikon: _ikon) ??
            Kategori(
              id: Repositori.idKategoriBerikutnya(),
              nama: _nama.text.trim(),
              ikon: _ikon,
            ),
      );
      if (!mounted) return;
      final pesan = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(tersimpan);
      pesan
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _ubah
                  ? '${_nama.text.trim()} diperbarui'
                  : '${_nama.text.trim()} ditambahkan',
            ),
          ),
        );
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = e.pesan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _ubah ? 'Ubah kategori' : 'Kategori baru',
                style: context.teks.titleLarge,
              ),
              const SizedBox(height: Jarak.sm),

              TextField(
                controller: _nama,
                autofocus: !_ubah,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _simpan(),
                decoration: InputDecoration(
                  labelText: 'Nama kategori',
                  hintText: 'Mis. Minuman Dingin',
                  errorText: _tersentuh && _kurang
                      ? 'Nama kategori wajib diisi.'
                      : null,
                ),
              ),

              const SizedBox(height: Jarak.sm),
              const JudulBagian('Ikon'),
              _PilihIkon(
                terpilih: _ikon,
                onPilih: (i) => setState(() => _ikon = i),
              ),

              if (_galat != null) ...[
                const SizedBox(height: Jarak.sm),
                BarisGalat(pesan: _galat!),
              ],

              const SizedBox(height: Jarak.sm),
              TombolPil(
                label: _ubah ? 'Simpan perubahan' : 'Tambah kategori',
                memproses: _menyimpan,
                onTekan: _menyimpan ? null : _simpan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petak ikon.
///
/// Yang terpilih dibedakan oleh latar tinta, bukan cuma bingkai: pada petak
/// sekecil ini bingkai satu piksel adalah perbedaan yang harus dicari, dan
/// pilihan yang harus dicari adalah pilihan yang tidak terlihat sudah dipilih.
class _PilihIkon extends StatelessWidget {
  const _PilihIkon({required this.terpilih, required this.onPilih});

  final IconData terpilih;
  final ValueChanged<IconData> onPilih;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Jarak.xs2,
      runSpacing: Jarak.xs2,
      children: [
        for (final ikon in ikonKategoriPilihan)
          Semantics(
            button: true,
            selected: ikon == terpilih,
            child: InkWell(
              onTap: () => onPilih(ikon),
              borderRadius: BorderRadius.circular(Lengkung.kontrol),
              child: IkonKotak(
                ikon,
                nada: ikon == terpilih ? NadaIkon.tinta : NadaIkon.netral,
                ukuran: 44,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hapus
// ---------------------------------------------------------------------------

/// Konfirmasi hapus.
///
/// Kategori kosong cukup dikonfirmasi. Kategori berisi produk menuntut tujuan
/// pindah lebih dulu — produk yang kategorinya lenyap tidak muncul di layar
/// Produk maupun di kasir, jadi ia hilang tanpa pernah dihapus, dan itu bentuk
/// kehilangan data yang paling sulit disadari.
Future<void> _hapus(
  BuildContext context, {
  required Kategori kategori,
  required int jumlahProduk,
  required List<Kategori> lainnya,
}) async {
  final pesan = ScaffoldMessenger.of(context);
  final terhapus = await showDialog<bool>(
    context: context,
    builder: (_) => _DialogHapus(
      kategori: kategori,
      jumlahProduk: jumlahProduk,
      lainnya: lainnya,
    ),
  );
  if (terhapus != true) return;

  pesan
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          jumlahProduk == 0
              ? '${kategori.nama} dihapus'
              : '${kategori.nama} dihapus · $jumlahProduk produk dipindahkan',
        ),
      ),
    );
}

class _DialogHapus extends StatefulWidget {
  const _DialogHapus({
    required this.kategori,
    required this.jumlahProduk,
    required this.lainnya,
  });

  final Kategori kategori;
  final int jumlahProduk;
  final List<Kategori> lainnya;

  @override
  State<_DialogHapus> createState() => _DialogHapusState();
}

class _DialogHapusState extends State<_DialogHapus> {
  late String _tujuan = widget.lainnya.first.id;
  bool _menyimpan = false;
  String? _galat;

  bool get _adaProduk => widget.jumlahProduk > 0;

  Future<void> _hapus() async {
    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      await Repositori.hapusKategori(
        widget.kategori.id,
        pindahkanKe: _adaProduk ? _tujuan : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = e.pesan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hapus ${widget.kategori.nama}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _adaProduk
                ? '${widget.jumlahProduk} produk masih ada di kategori ini. '
                      'Produknya tidak ikut terhapus — pilih kategori '
                      'tujuannya.'
                : 'Kategori ini kosong, jadi tidak ada produk yang terpengaruh.',
            style: context.teks.bodyMedium?.copyWith(height: 1.45),
          ),
          if (_adaProduk) ...[
            const SizedBox(height: Jarak.sm),
            // Nilai dan penanganannya dipegang RadioGroup, bukan diulang di
            // tiap baris — itu yang membuat "dua radio tercentang sekaligus"
            // tidak bisa terjadi sama sekali.
            RadioGroup<String>(
              groupValue: _tujuan,
              onChanged: (v) {
                if (_menyimpan || v == null) return;
                setState(() => _tujuan = v);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final k in widget.lainnya)
                    RadioListTile<String>(
                      value: k.id,
                      title: Text(k.nama),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
          ],
          if (_galat != null) ...[
            const SizedBox(height: Jarak.xs),
            BarisGalat(pesan: _galat!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _menyimpan ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _menyimpan ? null : _hapus,
          style: FilledButton.styleFrom(
            backgroundColor: context.aksen.bahaya,
            foregroundColor: Colors.white,
          ),
          child: Text(_menyimpan ? 'Menghapus…' : 'Hapus'),
        ),
      ],
    );
  }
}
