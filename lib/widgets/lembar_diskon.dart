import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';

/// Modal bottom sheet untuk mengatur Diskon POS (Persen atau Nominal).
class LembarDiskon extends StatefulWidget {
  const LembarDiskon({
    super.key,
    required this.subtotal,
    this.diskonTipeAwal,
    this.diskonNilaiAwal = 0,
  });

  final int subtotal;
  final String? diskonTipeAwal;
  final int diskonNilaiAwal;

  /// Membuka modal dan mengembalikan record (diskonTipe, diskonNilai) atau null jika dihapus/batal.
  static Future<(String?, int)?> tampilkan(
    BuildContext context, {
    required int subtotal,
    String? diskonTipeAwal,
    int diskonNilaiAwal = 0,
  }) {
    return showModalBottomSheet<(String?, int)?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => LembarDiskon(
        subtotal: subtotal,
        diskonTipeAwal: diskonTipeAwal,
        diskonNilaiAwal: diskonNilaiAwal,
      ),
    );
  }

  @override
  State<LembarDiskon> createState() => _LembarDiskonState();
}

class _LembarDiskonState extends State<LembarDiskon> {
  late String _tipe; // 'PERSEN' atau 'NOMINAL'
  final _kendaliNilai = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tipe = widget.diskonTipeAwal ?? 'PERSEN';
    if (widget.diskonNilaiAwal > 0) {
      _kendaliNilai.text = widget.diskonNilaiAwal.toString();
    }
  }

  @override
  void dispose() {
    _kendaliNilai.dispose();
    super.dispose();
  }

  int get _nilaiInput => int.tryParse(_kendaliNilai.text) ?? 0;

  int get _nominalPotongan {
    final v = _nilaiInput;
    if (v <= 0) return 0;
    if (_tipe == 'PERSEN') {
      final p = v.clamp(0, 100);
      return (widget.subtotal * p / 100).round();
    }
    return v.clamp(0, widget.subtotal);
  }

  int get _totalAkhir => (widget.subtotal - _nominalPotongan).clamp(0, 999999999999);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(Jarak.sm, 0, Jarak.sm, Jarak.sm + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.discount_outlined,
                  size: 24,
                  color: context.warna.onSurface,
                ),
                const SizedBox(width: Jarak.xs2),
                Expanded(
                  child: Text(
                    'Atur Diskon Transaksi',
                    style: context.teks.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Berikan diskon persen (%) atau nominal (Rp) pada total keranjang.',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Jarak.sm),

            // Pilihan Jenis Diskon (% vs Rp)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.percent, size: 16),
                    label: const Text('Diskon Persen (%)'),
                    selected: _tipe == 'PERSEN',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _tipe = 'PERSEN';
                          _kendaliNilai.clear();
                        });
                      }
                    },
                    selectedColor: context.aksen.fokus,
                    labelStyle: TextStyle(
                      color: _tipe == 'PERSEN'
                          ? context.aksen.atasFokus
                          : context.warna.onSurface,
                      fontWeight:
                          _tipe == 'PERSEN' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.money, size: 16),
                    label: const Text('Diskon Nominal (Rp)'),
                    selected: _tipe == 'NOMINAL',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _tipe = 'NOMINAL';
                          _kendaliNilai.clear();
                        });
                      }
                    },
                    selectedColor: context.aksen.fokus,
                    labelStyle: TextStyle(
                      color: _tipe == 'NOMINAL'
                          ? context.aksen.atasFokus
                          : context.warna.onSurface,
                      fontWeight:
                          _tipe == 'NOMINAL' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Jarak.xs),

            // Input Angka Diskon
            TextField(
              controller: _kendaliNilai,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _tipe == 'PERSEN'
                    ? 'Besar Diskon (%)'
                    : 'Besar Diskon (Rp)',
                hintText: _tipe == 'PERSEN' ? 'Contoh: 10' : 'Contoh: 5000',
                prefixText: _tipe == 'NOMINAL' ? 'Rp ' : null,
                suffixText: _tipe == 'PERSEN' ? '%' : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Jarak.xs2),

            // Tombol Jalan Pintas
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_tipe == 'PERSEN') ...[
                    for (final p in [5, 10, 15, 20, 25, 50])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text('$p%'),
                          onPressed: () {
                            setState(() {
                              _kendaliNilai.text = p.toString();
                            });
                          },
                        ),
                      ),
                  ] else ...[
                    for (final n in [2000, 5000, 10000, 20000, 50000])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(rupiah(n)),
                          onPressed: () {
                            setState(() {
                              _kendaliNilai.text = n.toString();
                            });
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Jarak.sm),

            // Ringkasan Kalkulasi Diskon
            Container(
              padding: const EdgeInsets.all(Jarak.xs),
              decoration: BoxDecoration(
                color: context.warna.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(Lengkung.kontrol),
                border: Border.all(color: context.warna.outline),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal:', style: context.teks.bodySmall),
                      Text(rupiah(widget.subtotal), style: context.teks.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tipe == 'PERSEN' && _nilaiInput > 0
                            ? 'Potongan Diskon (${_nilaiInput.clamp(0, 100)}%):'
                            : 'Potongan Diskon:',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.aksen.bahaya,
                        ),
                      ),
                      Text(
                        '-${rupiah(_nominalPotongan)}',
                        style: context.teks.bodySmall?.copyWith(
                          color: context.aksen.bahaya,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Bayar:',
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rupiah(_totalAkhir),
                        style: context.teks.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.aksen.fokus,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Jarak.md),

            Row(
              children: [
                if (widget.diskonNilaiAwal > 0 || _nilaiInput > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.aksen.bahaya,
                      ),
                      onPressed: () {
                        Navigator.pop(context, (null, 0));
                      },
                      child: const Text('Hapus Diskon'),
                    ),
                  ),
                if (widget.diskonNilaiAwal > 0 || _nilaiInput > 0)
                  const SizedBox(width: Jarak.xs),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _nilaiInput <= 0
                        ? null
                        : () {
                            Navigator.pop(context, (_tipe, _nilaiInput));
                          },
                    child: const Text('Terapkan Diskon'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
