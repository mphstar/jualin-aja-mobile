import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/kartu.dart';
import '../widgets/tombol_pil.dart';
import 'kategori_screen.dart' show suntingKategori;

/// Formulir tambah / ubah produk.
///
/// Satu layar untuk keduanya. Aturan isiannya identik, dan memisahkannya
/// berarti menggandakan validasi — tempat paling mudah untuk membuat "tambah"
/// menerima sesuatu yang ditolak "ubah".
class FormProdukScreen extends StatefulWidget {
  const FormProdukScreen({super.key, required this.kategori, this.produk});

  final List<Kategori> kategori;

  /// Null berarti produk baru.
  final Produk? produk;

  @override
  State<FormProdukScreen> createState() => _FormProdukScreenState();
}

class _FormProdukScreenState extends State<FormProdukScreen> {
  final _kunciForm = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _satuan;
  late final TextEditingController _stok;

  /// Salinan lokal, bukan `widget.kategori` langsung.
  ///
  /// Kategori bisa ditambah dari layar ini juga, dan daftar yang dititipkan
  /// pemanggil tidak akan tahu soal itu. Menyimpan salinannya membuat kategori
  /// yang baru dibuat langsung muncul sebagai chip — tanpa menutup formulir dan
  /// kehilangan nama serta harga yang sudah terlanjur diketik.
  late List<Kategori> _kategori;

  late String _kategoriId;
  late bool _lacakStok;
  bool _menyimpan = false;
  String? _galat;

  bool get _ubah => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _nama = TextEditingController(text: p?.nama ?? '');
    _harga = TextEditingController(text: p == null ? '' : angka(p.hargaJual));
    _satuan = TextEditingController(text: p?.satuan ?? 'pcs');
    _stok = TextEditingController(text: p == null ? '' : angka(p.stok));
    _kategori = List.of(widget.kategori);
    _kategoriId = p?.kategoriId ?? _kategori.first.id;
    _lacakStok = p?.lacakStok ?? false;
  }

  /// Buka lembar kategori baru, lalu langsung pilih yang tersimpan.
  ///
  /// Membuat kategori tanpa langsung memilihnya adalah tiga ketukan yang
  /// terlihat seperti tidak terjadi apa-apa: chipnya bertambah, tapi yang
  /// tercentang masih yang lama.
  Future<void> _tambahKategori() async {
    final baru = await suntingKategori(context, kategori: null);
    if (baru == null || !mounted) return;

    setState(() {
      // Bisa saja id-nya sudah ada kalau lembarnya dipakai untuk menyunting;
      // di sini ia selalu baru, tapi penggantinya tetap ditangani supaya
      // daftarnya tidak pernah berisi dua kategori berid sama.
      final i = _kategori.indexWhere((k) => k.id == baru.id);
      if (i >= 0) {
        _kategori[i] = baru;
      } else {
        _kategori.add(baru);
      }
      _kategoriId = baru.id;
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _satuan.dispose();
    _stok.dispose();
    super.dispose();
  }

  int _bacaAngka(TextEditingController c) => bacaNominal(c.text);

  Future<void> _simpan() async {
    if (!_kunciForm.currentState!.validate()) return;

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    final produk = Produk(
      id: widget.produk?.id ?? Repositori.idProdukBerikutnya(),
      nama: _nama.text.trim(),
      kategoriId: _kategoriId,
      hargaJual: _bacaAngka(_harga),
      satuan: _satuan.text.trim().isEmpty ? 'pcs' : _satuan.text.trim(),
      lacakStok: _lacakStok,
      // Stok hanya berarti kalau dilacak. Menyimpan angka sisa dari toggle yang
      // sudah dimatikan berarti menyimpan angka yang tidak pernah benar.
      stok: _lacakStok ? _bacaAngka(_stok) : 0,
      gambarUrl: widget.produk?.gambarUrl,
    );

    try {
      await Repositori.simpanProduk(produk);
      if (!mounted) return;
      Navigator.of(context).pop(produk);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _ubah
                  ? '${produk.nama} diperbarui'
                  : '${produk.nama} ditambahkan',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_ubah ? 'Ubah produk' : 'Produk baru'),
        leading: IconButton(
          onPressed: _menyimpan ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
          tooltip: 'Batal',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _kunciForm,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Jarak.sm,
                        Jarak.xs,
                        Jarak.sm,
                        Jarak.sm,
                      ),
                      children: [
                        const JudulBagian('Identitas'),
                        TextFormField(
                          controller: _nama,
                          autofocus: !_ubah,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama produk',
                            hintText: 'Mis. Kopi Susu Gula Aren',
                          ),
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'Nama produk wajib diisi.'
                              : null,
                        ),
                        const SizedBox(height: Jarak.sm),
                        Text(
                          'Kategori',
                          style: context.teks.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: Jarak.xs2),
                        Wrap(
                          spacing: Jarak.xs2,
                          runSpacing: Jarak.xs2,
                          children: [
                            for (final k in _kategori)
                              ChoiceChip(
                                label: Text(k.nama),
                                avatar: Icon(k.ikon, size: 18),
                                selected: _kategoriId == k.id,
                                onSelected: (_) =>
                                    setState(() => _kategoriId = k.id),
                              ),
                            // Berdiri di ujung barisan chip, bukan di menu lain.
                            // Kebutuhan "kategorinya belum ada" muncul persis
                            // saat mata sedang menyapu daftar ini dan tidak
                            // menemukan yang dicari.
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 18),
                              label: const Text('Kategori baru'),
                              onPressed: _menyimpan ? null : _tambahKategori,
                            ),
                          ],
                        ),

                        const SizedBox(height: Jarak.md),
                        const JudulBagian('Harga & satuan'),
                        TextFormField(
                          controller: _harga,
                          keyboardType: const TextInputType.numberWithOptions(),
                          inputFormatters: [FormatRibuan()],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Harga jual',
                            prefixText: 'Rp  ',
                            hintText: '0',
                          ),
                          validator: (v) => _bacaAngka(_harga) <= 0
                              ? 'Harga jual harus lebih dari nol.'
                              : null,
                        ),
                        const SizedBox(height: Jarak.sm),
                        TextFormField(
                          controller: _satuan,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                            hintText: 'pcs',
                          ),
                        ),
                        const SizedBox(height: Jarak.xs2),
                        Wrap(
                          spacing: Jarak.xs2,
                          runSpacing: Jarak.xs2,
                          children: [
                            for (final s in satuanUmum)
                              ActionChip(
                                label: Text(s),
                                onPressed: () => setState(() {
                                  _satuan.text = s;
                                }),
                              ),
                          ],
                        ),

                        const SizedBox(height: Jarak.md),
                        const JudulBagian('Stok'),
                        _SakelarStok(
                          aktif: _lacakStok,
                          onUbah: (v) => setState(() => _lacakStok = v),
                        ),
                        if (_lacakStok) ...[
                          const SizedBox(height: Jarak.sm),
                          TextFormField(
                            controller: _stok,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FormatRibuan()],
                            decoration: InputDecoration(
                              labelText: 'Stok saat ini',
                              suffixText: _satuan.text.trim().isEmpty
                                  ? 'pcs'
                                  : _satuan.text.trim(),
                              hintText: '0',
                            ),
                            validator: (v) => _bacaAngka(_stok) < 0
                                ? 'Stok tidak boleh negatif.'
                                : null,
                          ),
                        ],

                        if (_galat != null) ...[
                          const SizedBox(height: Jarak.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: context.aksen.bahaya,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _galat!,
                                  style: context.teks.bodySmall?.copyWith(
                                    color: context.aksen.bahaya,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Jarak.sm,
                      0,
                      Jarak.sm,
                      Jarak.sm,
                    ),
                    child: TombolPil(
                      label: _ubah ? 'Simpan perubahan' : 'Tambah produk',
                      memproses: _menyimpan,
                      onTekan: _menyimpan ? null : _simpan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sakelar pelacakan stok, lengkap dengan akibatnya.
///
/// Kalimat akibatnya ada karena "lacak stok" terdengar seperti pilihan
/// tampilan, padahal ia menentukan apakah produk ini bisa habis dan berhenti
/// bisa dijual.
class _SakelarStok extends StatelessWidget {
  const _SakelarStok({required this.aktif, required this.onUbah});

  final bool aktif;
  final ValueChanged<bool> onUbah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lacak stok',
                  style: context.teks.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aktif
                      ? 'Stok berkurang otomatis tiap terjual, dan produk '
                            'terkunci saat habis.'
                      : 'Produk selalu bisa dijual, berapa pun sisanya.',
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Jarak.xs2),
          Switch(value: aktif, onChanged: onUbah),
        ],
      ),
    );
  }
}
