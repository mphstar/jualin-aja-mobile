/// Konfigurasi koneksi ke backend.
///
/// Base URL dipisah agar mudah diganti saat pindah ke ngrok atau produksi.
/// Nilainya bisa diubah saat aplikasi berjalan lewat backdoor debug (lihat
/// `screens/backdoor_screen.dart`) dan tersimpan di disk, tanpa perlu
/// mengompilasi ulang.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// URL dasar API bawaan. Ubah ke ngrok URL atau domain produksi nanti.
///
/// - Android emulator: `http://10.0.2.2:8000`
/// - iOS simulator / web: `http://localhost:8000`
/// - Perangkat fisik di jaringan lokal: `http://<IP-komputer>:8000`
const basisApiBawaan = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://2b94-103-109-209-249.ngrok-free.app',
);

/// URL dasar API yang aktif saat ini.
///
/// Nilai awalnya [basisApiBawaan], lalu bisa ditimpa lewat backdoor debug dan
/// bertahan antar sesi.
String basisApi = basisApiBawaan;

const _kunciBasisApi = 'basis_api';

/// Muat basis API tersimpan dari disk. Dipanggil sekali saat aplikasi mulai.
Future<void> muatBasisApi() async {
  final prefs = await SharedPreferences.getInstance();
  basisApi = prefs.getString(_kunciBasisApi) ?? basisApiBawaan;
}

/// Simpan basis API baru dan langsung memakainya.
Future<void> simpanBasisApi(String url) async {
  basisApi = url;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kunciBasisApi, url);
}

/// Kembalikan basis API ke nilai bawaan.
Future<void> pulihkanBasisApi() => simpanBasisApi(basisApiBawaan);

/// Prefiks rute API mobile.
const prefiks = '/api/mobile/v1';

/// Timeout permintaan HTTP dalam detik.
const timeoutDetik = 30;
