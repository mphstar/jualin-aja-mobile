import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/data/model.dart';
import 'package:mobile/data/parser.dart';

/// Tagihan Pustaka di lapisan data.
///
/// Tagihan pembelian konten memakai `durasi` placeholder dari server (kolomnya
/// NOT NULL di sana) dan tidak punya `berlakuSampai`. Sebelum ada `tipe`,
/// keduanya tidak bisa dibedakan dari tagihan langganan, dan `_tanggal(null)`
/// yang mengembalikan `DateTime.now()` membuat layar menuliskan "Langganan
/// aktif sampai hari ini" untuk pembelian yang sebenarnya permanen.
void main() {
  /// Badan `TagihanResource` yang sah, dengan bagian yang diuji bisa ditimpa.
  Map<String, dynamic> badan({String? tipe, String? berlakuSampai}) => {
    'id': '12',
    'nomorInvoice': 'INV/2026/0130',
    'tipe': tipe,
    'durasi': 'BULANAN',
    'nominal': 35000,
    'saluran': 'qris',
    'status': 'LUNAS',
    'dibuat': '2026-09-14T13:00:00.000000Z',
    'batasBayar': '2026-09-14T14:00:00.000000Z',
    'batasSaluran': null,
    'berlakuSampai': berlakuSampai,
    'dibayarPada': '2026-09-14T13:05:00.000000Z',
    'instruksi': null,
    'tautanBayar': null,
  };

  group('tipe tagihan', () {
    test('pembelian satuan terbaca sebagai Pustaka', () {
      final t = tagihanDariJson(badan(tipe: 'PUSTAKA_SATUAN'));

      expect(t.tipe, TipeTagihan.pustakaSatuan);
      expect(t.tipe.pustaka, isTrue);
    });

    test('langganan tetap terbaca sebagai langganan', () {
      final t = tagihanDariJson(
        badan(tipe: 'LANGGANAN', berlakuSampai: '2026-10-14T13:00:00.000000Z'),
      );

      expect(t.tipe, TipeTagihan.langganan);
      expect(t.tipe.pustaka, isFalse);
    });

    test('server lama tanpa `tipe` dianggap langganan, bukan galat', () {
      final t = tagihanDariJson(
        badan(berlakuSampai: '2026-10-14T13:00:00.000000Z'),
      );

      expect(t.tipe, TipeTagihan.langganan);
    });

    test('tipe tak dikenal tidak menjatuhkan parsing', () {
      final t = tagihanDariJson(badan(tipe: 'SESUATU_YANG_BARU'));

      expect(t.tipe, TipeTagihan.langganan);
    });

    test('salin mengekalkan tipe', () {
      final t = tagihanDariJson(badan(tipe: 'PUSTAKA_SATUAN'));

      expect(t.salin(status: StatusBayar.menunggu).tipe, t.tipe);
    });
  });

  group('berlakuSampai', () {
    test(
      'pembelian konten tidak punya masa berlaku — dan itu null, bukan hari ini',
      () {
        final t = tagihanDariJson(badan(tipe: 'PUSTAKA_SATUAN'));

        // Inti regresinya: `null` dulu berubah jadi `DateTime.now()`, dan layar
        // menuliskannya sebagai tanggal berakhir.
        expect(t.berlakuSampai, isNull);
      },
    );

    test('langganan membawa tanggal berakhirnya', () {
      final t = tagihanDariJson(
        badan(tipe: 'LANGGANAN', berlakuSampai: '2026-10-14T13:00:00.000000Z'),
      );

      expect(t.berlakuSampai, isNotNull);
      expect(t.berlakuSampai!.toUtc().day, 14);
    });

    test('batas bayar tetap terisi walau kontennya permanen', () {
      // Yang permanen itu aksesnya, bukan tagihannya — kode QR tetap mati.
      final t = tagihanDariJson(badan(tipe: 'PUSTAKA_SATUAN'));

      expect(t.batasBayar.toUtc().hour, 14);
    });
  });
}
