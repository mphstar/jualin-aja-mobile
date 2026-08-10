import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kata sandi untuk membuka backdoor debug. Ganti di sini jika perlu.
const kataSandiBackdoor = 'backdoor';

const _kunciModeDebug = 'mode_debug';

/// Status mode debug. Saat aktif, aplikasi menampilkan bilah penanda kecil di
/// atas layar supaya penguji sadar bahwa mode debug menyala.
final ValueNotifier<bool> modeDebug = ValueNotifier(false);

/// Muat preferensi backdoor dari disk. Dipanggil sekali saat aplikasi mulai.
Future<void> muatBackdoor() async {
  final prefs = await SharedPreferences.getInstance();
  modeDebug.value = prefs.getBool(_kunciModeDebug) ?? false;
}

/// Simpan status mode debug.
Future<void> setModeDebug(bool aktif) async {
  modeDebug.value = aktif;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kunciModeDebug, aktif);
}

/// Satu entri log error.
class EntriLog {
  const EntriLog({
    required this.waktu,
    required this.sumber,
    required this.pesan,
    this.stack,
  });

  final DateTime waktu;
  final String sumber;
  final String pesan;
  final String? stack;
}

/// Log error terbaru, ditampilkan di layar backdoor.
///
/// Error SELALU direkam terlepas dari status mode debug — mode debug hanya
/// mengatur penanda di layar, bukan apakah error dicatat.
final ValueNotifier<List<EntriLog>> logError = ValueNotifier(const []);

/// Jumlah entri log maksimal yang dipertahankan.
const _batasLog = 200;

/// Catat satu error ke [logError].
void catatError(String sumber, Object error, [StackTrace? stack]) {
  final daftar = List<EntriLog>.of(logError.value);
  if (daftar.length >= _batasLog) {
    daftar.removeRange(0, daftar.length - _batasLog + 1);
  }
  daftar.add(
    EntriLog(
      waktu: DateTime.now(),
      sumber: sumber,
      pesan: error.toString(),
      stack: stack?.toString(),
    ),
  );
  logError.value = daftar;
}

/// Kosongkan log error.
void bersihkanLog() => logError.value = const [];
