import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/klaim.dart';
import 'package:mobile/data/model.dart';

/// Layar klaim tidak bisa diuji lewat widget: `masuk()` di lapisan jaringan
/// masih rusak, jadi seluruh keputusan layar itu ditaruh di `klaim.dart` dan
/// diuji langsung di sini.

Ebook _ebook({
  required String id,
  JenisKonten jenis = JenisKonten.resep,
  String statusAkses = 'TERKUNCI',
}) => Ebook(
  id: id,
  jenis: jenis,
  judul: 'Konten $id',
  kategori: 'Minuman',
  kategoriPrompt: jenis == JenisKonten.prompt ? 'Foto Produk' : null,
  deskripsi: 'Deskripsi $id',
  jumlahHalaman: 40,
  ukuranMb: 3.2,
  statusAkses: statusAkses,
  bisaKlaim: statusAkses == 'BISA_KLAIM',
  terbuka: statusAkses == 'TERBUKA',
);

Tagihan _tagihan({
  TipeTagihan tipe = TipeTagihan.langganan,
  StatusBayar status = StatusBayar.lunas,
  DateTime? batasBayar,
}) => Tagihan(
  id: 'inv-1',
  nomorInvoice: 'INV/2026/0130',
  tipe: tipe,
  durasi: DurasiPaket.bulanan,
  nominal: 99_000,
  saluran: SaluranBayar.qris,
  status: status,
  dibuat: DateTime(2026, 9, 14, 20),
  // Jauh di masa depan supaya `lewatBatas` tidak bergantung jam mesin yang
  // menjalankan tes.
  batasBayar: batasBayar ?? DateTime(2030, 1, 1),
);

void main() {
  group('ringkasanKlaim', () {
    test('selalu dua bagian dengan urutan tetap: Resep lalu Prompt', () {
      final hasil = ringkasanKlaim([]);

      expect(hasil.bagian, hasLength(2));
      expect(hasil.bagian[0].jenis, JenisKonten.resep);
      expect(hasil.bagian[1].jenis, JenisKonten.prompt);
      expect(hasil.bagian[0].label, 'Resep');
      expect(hasil.bagian[1].label, 'Prompt');
    });

    test('katalog kosong berarti kedua bagian kosong, bukan terpakai', () {
      final hasil = ringkasanKlaim([]);

      expect(hasil.bagian.every((b) => b.status == StatusJatah.kosong), isTrue);
      expect(hasil.jatahTerpakai, 0);
      expect(hasil.jatahTersedia, 0);
      expect(hasil.selesai, isTrue);
    });

    test('memisahkan konten yang bisa diklaim per jenis', () {
      final hasil = ringkasanKlaim([
        _ebook(id: '1', statusAkses: 'BISA_KLAIM'),
        _ebook(id: '2'),
        _ebook(id: '3', jenis: JenisKonten.prompt, statusAkses: 'BISA_KLAIM'),
      ]);

      expect(hasil.bagian[0].bisaDiklaim.map((e) => e.id), ['1']);
      expect(hasil.bagian[1].bisaDiklaim.map((e) => e.id), ['3']);
      expect(hasil.jatahTersedia, 2);
      expect(hasil.jatahTerpakai, 0);
      expect(hasil.selesai, isFalse);
    });

    test('jenis yang punya konten tapi tak satu pun bisa diklaim = terpakai', () {
      // Inilah yang membuat penghitung "x dari 2 jatah terpakai" jujur: jatah
      // habis dibaca dari server (`statusAkses`), bukan ditebak aplikasi.
      final hasil = ringkasanKlaim([
        _ebook(id: '1', statusAkses: 'TERBUKA'),
        _ebook(id: '2'),
      ]);

      expect(hasil.bagian[0].status, StatusJatah.terpakai);
      expect(hasil.bagian[1].status, StatusJatah.kosong);
      expect(hasil.jatahTerpakai, 1);
      expect(hasil.jatahTersedia, 0);
      expect(hasil.selesai, isTrue);
    });

    test('satu jatah terpakai tidak menutup jatah jenis lain', () {
      final hasil = ringkasanKlaim([
        _ebook(id: '1', statusAkses: 'TERBUKA'),
        _ebook(id: '2', jenis: JenisKonten.prompt, statusAkses: 'BISA_KLAIM'),
      ]);

      expect(hasil.bagian[0].status, StatusJatah.terpakai);
      expect(hasil.bagian[1].status, StatusJatah.tersedia);
      expect(hasil.jatahTerpakai, 1);
      expect(hasil.jatahTersedia, 1);
      expect(hasil.selesai, isFalse);
    });

    test('label jenis tersisa hanya menyebut jatah yang belum dipakai', () {
      // Banner Pustaka memakai ini untuk kalimatnya. Menyebut "Resep & Prompt"
      // padahal Resep-nya sudah dipakai berarti mengundang orang mengklaim
      // sesuatu yang tidak ada.
      final hasil = ringkasanKlaim([
        _ebook(id: '1', statusAkses: 'TERBUKA'),
        _ebook(id: '2', jenis: JenisKonten.prompt, statusAkses: 'BISA_KLAIM'),
      ]);

      expect(hasil.labelTersedia, ['Prompt']);
    });

    test('dua-duanya tersisa berarti keduanya disebut', () {
      final hasil = ringkasanKlaim([
        _ebook(id: '1', statusAkses: 'BISA_KLAIM'),
        _ebook(id: '2', jenis: JenisKonten.prompt, statusAkses: 'BISA_KLAIM'),
      ]);

      expect(hasil.labelTersedia, ['Resep', 'Prompt']);
    });
  });

  group('tawarkanKlaim', () {
    test('tagihan langganan yang lunas menawarkan klaim', () {
      expect(tawarkanKlaim(_tagihan()), isTrue);
    });

    test('tagihan Pustaka satuan tidak pernah menawarkan klaim', () {
      // Yang dibelinya satu konten tertentu, bukan jatah klaim — menawarkan
      // klaim di situ justru menyesatkan.
      expect(
        tawarkanKlaim(_tagihan(tipe: TipeTagihan.pustakaSatuan)),
        isFalse,
      );
    });

    test('tagihan yang belum lunas tidak menawarkan klaim', () {
      for (final status in [
        StatusBayar.menunggu,
        StatusBayar.gagal,
        StatusBayar.kedaluwarsa,
      ]) {
        expect(
          tawarkanKlaim(_tagihan(status: status)),
          isFalse,
          reason: 'status $status seharusnya tidak menawarkan klaim',
        );
      }
    });

    test('tagihan menunggu yang lewat batas tidak menawarkan klaim', () {
      // `statusKini` yang dipakai, bukan `status` mentah — tagihan yang lewat
      // batas tapi masih tercatat menunggu adalah tagihan yang berbohong.
      expect(
        tawarkanKlaim(
          _tagihan(
            status: StatusBayar.menunggu,
            batasBayar: DateTime(2020, 1, 1),
          ),
        ),
        isFalse,
      );
    });
  });
}
