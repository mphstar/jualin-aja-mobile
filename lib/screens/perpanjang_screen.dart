import 'package:flutter/material.dart';

import '../data/model.dart';
import '../data/repositori.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/bingkai.dart';
import '../widgets/kartu.dart';
import '../widgets/lencana.dart';
import '../widgets/rangka.dart';
import 'status_bayar_screen.dart';

/// Pilih durasi dan saluran pembayaran, lalu buat tagihan.
///
/// Satu kalimat di layar ini yang paling menentukan apakah orang membayar
/// sekarang atau menunda sampai hari terakhir: **"sisa 5 hari Anda tidak
/// hangus"** (PRD §4.4). Tanpa itu, memperpanjang lebih awal terasa seperti
/// membuang sisa yang sudah dibayar — dan orang menunggu sampai langganannya
/// benar-benar mati sebelum membayar lagi.
///
/// Harga hematnya **dihitung** dari [hargaPaket], bukan ditulis tangan. Klaim
/// diskon yang dipatok manual adalah klaim yang jadi bohong pada perubahan
/// harga pertama.
class PerpanjangScreen extends StatelessWidget {
  const PerpanjangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
        ),
        title: const Text('Perpanjang langganan'),
      ),
      body: Bingkai<Langganan>(
        ambil: Repositori.langganan,
        rangka: const Padding(
          padding: EdgeInsets.all(Jarak.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangkaPanel(tinggi: 92),
              SizedBox(height: Jarak.md),
              RangkaDaftar(baris: 3, tinggiBaris: 76),
            ],
          ),
        ),
        isi: (context, l) => _Isi(langganan: l),
      ),
    );
  }
}

class _Isi extends StatefulWidget {
  const _Isi({required this.langganan});

  final Langganan langganan;

  @override
  State<_Isi> createState() => _IsiState();
}

class _IsiState extends State<_Isi> {
  // Enam bulan sebagai bawaan, bukan satu bulan: ia titik tengah yang wajar
  // dan sudah membawa hemat nyata. Bawaan termurah membuat pilihan lain
  // terlihat seperti membayar lebih mahal untuk hal yang sama.
  DurasiPaket _durasi = DurasiPaket.semesteran;
  SaluranBayar? _saluran = SaluranBayar.qris;
  bool _memproses = false;

  Future<void> _bayar() async {
    setState(() => _memproses = true);
    try {
      final tagihan = await Repositori.buatTagihan(
        durasi: _durasi,
        saluran: _saluran!,
      );
      if (!mounted) return;
      // MENGGANTI, bukan menumpuk. Begitu tagihan ada, kembali ke pemilih
      // paket adalah jalan menuju tagihan KEDUA untuk hal yang sama — dan
      // pengguna yang punya dua nomor VA aktif akan membayar yang salah.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => StatusBayarScreen(tagihan: tagihan),
        ),
      );
    } on GagalMuat catch (e) {
      if (!mounted) return;
      setState(() => _memproses = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.pesan)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.langganan;
    final akhirBaru = l.berakhirSetelahPerpanjang(_durasi);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Jarak.sm,
              Jarak.sm,
              Jarak.sm,
              Jarak.sm,
            ),
            children: [
              _KartuSekarang(langganan: l),
              const SizedBox(height: Jarak.md),

              const JudulBagian('Pilih durasi'),
              for (final d in paketDijual) ...[
                _PilihanPaket(
                  durasi: d,
                  terpilih: _durasi == d,
                  onTekan: () => setState(() => _durasi = d),
                ),
                const SizedBox(height: Jarak.xs2),
              ],
              const SizedBox(height: Jarak.xs),

              const JudulBagian('Metode pembayaran'),
              _DaftarSaluran(
                terpilih: _saluran,
                onPilih: (s) => setState(() => _saluran = s),
              ),
              const SizedBox(height: Jarak.md),

              _KartuRincian(
                langganan: l,
                durasi: _durasi,
                akhirBaru: akhirBaru,
              ),
            ],
          ),
        ),
        _BilahBayar(
          nominal: _durasi.harga,
          // Tombol mati sampai saluran dipilih. Membuatnya hidup lalu menolak
          // di layar berikutnya adalah menunda kabar buruk satu ketukan.
          onBayar: _saluran == null ? null : _bayar,
          memproses: _memproses,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _KartuSekarang extends StatelessWidget {
  const _KartuSekarang({required this.langganan});

  final Langganan langganan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paket sekarang · ${langganan.durasi.label}',
                    style: context.teks.bodySmall?.copyWith(
                      color: context.warna.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sisaHari(langganan.sisaHari),
                    style: context.teks.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Jarak.xs2),
            Lencana.langganan(langganan.status),
          ],
        ),
      ),
    );
  }
}

class _PilihanPaket extends StatelessWidget {
  const _PilihanPaket({
    required this.durasi,
    required this.terpilih,
    required this.onTekan,
  });

  final DurasiPaket durasi;
  final bool terpilih;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final hemat = durasi.hematPersen;

    return Semantics(
      button: true,
      selected: terpilih,
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        child: AnimatedContainer(
          duration: Gerak.cepat,
          padding: const EdgeInsets.all(Jarak.xs),
          decoration: BoxDecoration(
            color: context.warna.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(Lengkung.kontrol),
            border: Border.all(
              color: terpilih ? context.warna.onSurface : context.warna.outline,
              width: terpilih ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Radio(terpilih: terpilih),
              const SizedBox(width: Jarak.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      durasi.label,
                      style: context.teks.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // `Wrap`, bukan `Row`: pil hemat tidak bisa menyusut, dan
                    // pada 320 px ia mendorong harga per bulan keluar kartu.
                    // Dijatuhkan ke baris berikutnya jauh lebih baik daripada
                    // dipotong — dan `Wrap` tidak pernah bisa meluber.
                    Wrap(
                      spacing: Jarak.xs2,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${rupiah(durasi.perBulan)}/bulan',
                          style: context.teks.bodySmall?.copyWith(
                            color: context.warna.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (hemat > 0) _PilHemat(persen: hemat),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Jarak.xs2),
              Text(
                rupiah(durasi.harga),
                style: context.teks.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pil hemat memakai warna sukses — satu-satunya kroma di layar ini, dan ia
/// memang berstatus: angka itu benar atau tidak, bukan soal selera.
class _PilHemat extends StatelessWidget {
  const _PilHemat({required this.persen});

  final int persen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: context.aksen.suksesLembut,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
      ),
      child: Text(
        'Hemat $persen%',
        style: context.teks.labelSmall?.copyWith(
          color: context.aksen.sukses,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.terpilih});

  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Gerak.cepat,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: terpilih ? context.warna.onSurface : Colors.transparent,
        border: Border.all(
          color: terpilih ? context.warna.onSurface : context.warna.outline,
          width: terpilih ? 1 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: terpilih
          ? Icon(Icons.check, size: 13, color: context.warna.surface)
          : null,
    );
  }
}

class _DaftarSaluran extends StatelessWidget {
  const _DaftarSaluran({required this.terpilih, required this.onPilih});

  final SaluranBayar? terpilih;
  final ValueChanged<SaluranBayar> onPilih;

  @override
  Widget build(BuildContext context) {
    return KartuDaftar(
      anak: [
        for (final s in SaluranBayar.values)
          BarisDaftar(
            awalan: _Radio(terpilih: terpilih == s),
            judul: s.label,
            keterangan: s.keterangan,
            bawahAkhiran: Icon(
              switch (s.grup) {
                GrupSaluran.qris => Icons.qr_code_2,
                GrupSaluran.virtualAccount => Icons.account_balance_outlined,
                GrupSaluran.eWallet => Icons.account_balance_wallet_outlined,
              },
              size: 22,
              color: context.warna.onSurfaceVariant,
            ),
            onTekan: () => onPilih(s),
          ),
      ],
    );
  }
}

/// Rincian yang menjawab pertanyaan sungguhan: *sisa hari saya hangus tidak?*
class _KartuRincian extends StatelessWidget {
  const _KartuRincian({
    required this.langganan,
    required this.durasi,
    required this.akhirBaru,
  });

  final Langganan langganan;
  final DurasiPaket durasi;
  final DateTime akhirBaru;

  @override
  Widget build(BuildContext context) {
    final menyambung = langganan.menyambung;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarisRincian(label: 'Paket', nilai: durasi.label),
            const SizedBox(height: 6),
            _BarisRincian(
              label: menyambung ? 'Disambung dari' : 'Mulai berlaku',
              nilai: tanggal(
                menyambung ? langganan.tanggalBerakhir : DateTime.now(),
              ),
            ),
            const SizedBox(height: 6),
            _BarisRincian(
              label: 'Berlaku sampai',
              nilai: tanggal(akhirBaru),
              tebal: true,
            ),
            const SizedBox(height: Jarak.xs),
            Container(
              padding: const EdgeInsets.all(Jarak.xs2),
              decoration: BoxDecoration(
                color: menyambung
                    ? context.aksen.suksesLembut
                    : context.aksen.isian,
                borderRadius: BorderRadius.circular(Lengkung.kecil),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    menyambung
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 16,
                    color: menyambung
                        ? context.aksen.sukses
                        : context.warna.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      menyambung
                          ? 'Sisa ${langganan.sisaHari} hari Anda tidak '
                                'hangus — masa aktif ditambahkan dari tanggal '
                                'berakhir yang sekarang.'
                          : 'Langganan sudah lewat, jadi masa aktif dihitung '
                                'mulai hari ini.',
                      style: context.teks.bodySmall?.copyWith(
                        color: menyambung
                            ? context.aksen.sukses
                            : context.warna.onSurfaceVariant,
                        height: 1.4,
                      ),
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

class _BarisRincian extends StatelessWidget {
  const _BarisRincian({
    required this.label,
    required this.nilai,
    this.tebal = false,
  });

  final String label;
  final String nilai;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.teks.bodySmall?.copyWith(
              color: context.warna.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: Jarak.xs2),
        Flexible(
          child: Text(
            nilai,
            textAlign: TextAlign.right,
            style: tebal
                ? context.teks.titleSmall
                : context.teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Bilah bayar menempel di bawah, tidak ikut menggulir.
///
/// Total dan tombolnya harus terlihat sepanjang orang memilih — kalau ia ikut
/// tergulir, setiap perbandingan harga menuntut gulir balik ke bawah.
class _BilahBayar extends StatelessWidget {
  const _BilahBayar({
    required this.nominal,
    required this.onBayar,
    required this.memproses,
  });

  final int nominal;
  final VoidCallback? onBayar;
  final bool memproses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.sm),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.warna.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: context.teks.bodyMedium?.copyWith(
                      color: context.warna.onSurfaceVariant,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    rupiah(nominal),
                    style: context.teks.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Jarak.xs),
            FilledButton(
              onPressed: memproses ? null : onBayar,
              child: memproses
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.warna.onPrimary,
                      ),
                    )
                  : Text(
                      onBayar == null
                          ? 'Pilih metode pembayaran'
                          : 'Bayar sekarang',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
