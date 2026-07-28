/// Konfigurasi koneksi ke backend.
///
/// Base URL dipisah agar mudah diganti saat pindah ke ngrok atau produksi.
/// Cukup ubah satu konstanta, bukan mencari di seluruh kode.
library;

/// URL dasar API backend. Ubah ke ngrok URL atau domain produksi nanti.
///
/// - Android emulator: `http://10.0.2.2:8000`
/// - iOS simulator / web: `http://localhost:8000`
/// - Perangkat fisik di jaringan lokal: `http://<IP-komputer>:8000`
const basisApi = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// Prefiks rute API mobile.
const prefiks = '/api/mobile/v1';

/// Timeout permintaan HTTP dalam detik.
const timeoutDetik = 30;
