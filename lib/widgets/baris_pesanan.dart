import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'blok_foto.dart';
import 'tombol_pil.dart';

/// Satu baris pesanan yang bisa diubah jumlahnya.
///
/// Dipakai di layar bayar dan di layar ubah pesanan piutang. Sengaja menerima
/// nilai mentah — nama, harga, jumlah — bukan `ItemKeranjang` atau `BarisStruk`:
/// keduanya bentuk yang berbeda (yang satu menunjuk produk, yang satu menyalin
/// harga saat itu), dan barisnya harus terlihat sama persis di kedua tempat
/// atau kasir akan mengira ia sedang menyunting benda yang berbeda.
///
/// Tombol kirinya berubah jadi tong sampah saat tinggal satu. Menekan "−" pada
/// item terakhir memang menghapusnya, dan ikon yang tidak mengakui itu membuat
/// penghapusan terasa seperti kecelakaan.
class BarisPesanan extends StatelessWidget {
  const BarisPesanan({
    super.key,
    required this.nama,
    required this.hargaSatuan,
    required this.jumlah,
    required this.onKurang,
    required this.onTambah,
    this.gambarUrl,
    this.aktif = true,
    this.bolehTambah = true,
  });

  final String nama;
  final int hargaSatuan;
  final int jumlah;
  final VoidCallback onKurang;
  final VoidCallback onTambah;
  final String? gambarUrl;
  final bool aktif;

  /// False saat stok tidak menyisakan ruang untuk satu lagi.
  final bool bolehTambah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Jarak.xs,
        vertical: Jarak.xs2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: BlokFoto(url: gambarUrl, tampilkanLabel: false),
          ),
          const SizedBox(width: Jarak.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: context.teks.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${rupiah(hargaSatuan)} · ${rupiah(hargaSatuan * jumlah)}',
                  style: context.teks.bodySmall?.copyWith(
                    color: context.warna.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Jarak.xs2),
          TombolBundar(
            ikon: jumlah == 1 ? Icons.delete_outline : Icons.remove,
            bahaya: jumlah == 1,
            onTekan: aktif ? onKurang : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$jumlah',
              textAlign: TextAlign.center,
              style: context.teks.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TombolBundar(
            ikon: Icons.add,
            utama: true,
            onTekan: aktif && bolehTambah ? onTambah : null,
          ),
        ],
      ),
    );
  }
}
