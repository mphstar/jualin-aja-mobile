import 'package:flutter/material.dart';

import '../data/model.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum NadaLencana { netral, sukses, peringatan, bahaya, info }

/// Lencana status: latar lembut + teks pekat + titik penanda.
///
/// Ini satu-satunya tempat kroma muncul di aplikasi monokrom ini, jadi ia
/// harus benar-benar berarti. Titik di sebelah kiri bukan hiasan — ia yang
/// membuat statusnya terbaca oleh mata yang tidak membedakan merah dan hijau.
class Lencana extends StatelessWidget {
  const Lencana(this.label, {super.key, this.nada = NadaLencana.netral});

  /// Status langganan → nada + label. Aturan warnanya sama dengan panel web.
  factory Lencana.langganan(StatusLangganan status, {Key? key}) {
    final (label, nada) = switch (status) {
      StatusLangganan.ujiCoba => ('Uji Coba', NadaLencana.info),
      StatusLangganan.aktif => ('Aktif', NadaLencana.sukses),
      StatusLangganan.akanBerakhir => ('Akan Berakhir', NadaLencana.peringatan),
      StatusLangganan.kedaluwarsa => ('Kedaluwarsa', NadaLencana.bahaya),
      StatusLangganan.nonaktif => ('Nonaktif', NadaLencana.netral),
    };
    return Lencana(label, key: key, nada: nada);
  }

  factory Lencana.transaksi(StatusTransaksi status, {Key? key}) {
    final (label, nada) = switch (status) {
      StatusTransaksi.selesai => ('Selesai', NadaLencana.sukses),
      StatusTransaksi.ditahan => ('Ditahan', NadaLencana.peringatan),
      StatusTransaksi.batal => ('Batal', NadaLencana.bahaya),
    };
    return Lencana(label, key: key, nada: nada);
  }

  final String label;
  final NadaLencana nada;

  @override
  Widget build(BuildContext context) {
    final a = context.aksen;
    final (latar, depan) = switch (nada) {
      NadaLencana.netral => (a.isian, context.warna.onSurfaceVariant),
      NadaLencana.sukses => (a.suksesLembut, a.sukses),
      NadaLencana.peringatan => (a.peringatanLembut, a.peringatan),
      NadaLencana.bahaya => (a.bahayaLembut, a.bahaya),
      NadaLencana.info => (a.infoLembut, a.info),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(Lengkung.bulat),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: depan, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.teks.labelSmall?.copyWith(
              color: depan,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
