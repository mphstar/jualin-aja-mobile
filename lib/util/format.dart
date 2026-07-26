/// Pemformat lokal Indonesia.
///
/// Ditulis tangan, bukan memakai `intl`, karena kebutuhannya cuma tiga bentuk
/// dan menambah paket untuk itu tidak sepadan. Kalau nanti butuh pelokalan
/// penuh, ganti berkas ini — pemanggilnya tidak berubah.
library;

const _bulanPendek = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agt',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// 18000 → "Rp 18.000"
String rupiah(int nilai) => 'Rp ${_pisahRibuan(nilai)}';

/// 18000 → "18.000" (tanpa awalan mata uang, untuk kolom angka)
String angka(int nilai) => _pisahRibuan(nilai);

String _pisahRibuan(int nilai) {
  final negatif = nilai < 0;
  final digit = nilai.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digit.length; i++) {
    if (i > 0 && (digit.length - i) % 3 == 0) buf.write('.');
    buf.write(digit[i]);
  }
  return negatif ? '-$buf' : buf.toString();
}

/// DateTime → "26 Jul 2026"
String tanggal(DateTime d) => '${d.day} ${_bulanPendek[d.month - 1]} ${d.year}';

/// DateTime → "14:30"
String jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// DateTime → "baru saja" · "12 menit lalu" · "3 jam lalu" · "kemarin"
String relatif(DateTime d) {
  final selisih = DateTime.now().difference(d);
  if (selisih.inMinutes < 1) return 'baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays == 1) return 'kemarin';
  if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
  return tanggal(d);
}

/// Sisa hari → kalimat manusiawi. Aturan yang sama dengan panel web.
String sisaHari(int hari) {
  if (hari > 1) return '$hari hari lagi';
  if (hari == 1) return 'Berakhir besok';
  if (hari == 0) return 'Berakhir hari ini';
  if (hari == -1) return 'Lewat 1 hari';
  return 'Lewat ${hari.abs()} hari';
}

const _hariPendek = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];

/// DateTime → "Sn" · "Sl" · … Dipakai sebagai label sumbu grafik, jadi
/// panjangnya dijaga dua huruf: tiga huruf sudah tidak muat di 320 px.
String hariPendek(DateTime d) => _hariPendek[d.weekday - 1];

/// DateTime → "26 Jul" (tanpa tahun). Untuk label yang ruangnya sempit.
String tanggalPendek(DateTime d) => '${d.day} ${_bulanPendek[d.month - 1]}';

/// 12400 → "12,4 rb" · 1250000 → "1,25 jt"
///
/// Hanya untuk label grafik dan angka sekilas. Nominal yang bisa disengketakan
/// — total struk, omzet di laporan — selalu memakai [rupiah] utuh.
String ringkasRupiah(int nilai) {
  if (nilai >= 1000000) {
    final jt = nilai / 1000000;
    return 'Rp ${jt.toStringAsFixed(jt >= 10 ? 0 : 1).replaceAll('.', ',')} jt';
  }
  if (nilai >= 1000) {
    final rb = nilai / 1000;
    return 'Rp ${rb.toStringAsFixed(rb >= 100 ? 0 : 0).replaceAll('.', ',')} rb';
  }
  return rupiah(nilai);
}

/// "Bintang Pratama" → "BP"
String inisial(String nama) {
  final bagian = nama.trim().split(RegExp(r'\s+'));
  return bagian.take(2).map((k) => k.isEmpty ? '' : k[0].toUpperCase()).join();
}
