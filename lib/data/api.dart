/// HTTP client untuk berkomunikasi dengan backend Laravel.
///
/// Satu titik keluar-masuk untuk semua permintaan API. Token disimpan di
/// SharedPreferences agar tetap tersedia setelah aplikasi ditutup. Semua
/// respons non-2xx diterjemahkan ke [GagalMuat] yang bisa ditangkap layar.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'repositori.dart' show GagalMuat;

const _kunciToken = 'auth_token';

/// Token bearer aktif. Null berarti belum masuk.
String? _token;

/// Apakah sesi sudah dimuat dari disk.
bool _sudahMuatToken = false;

// ---------------------------------------------------------------------------
// Manajemen token
// ---------------------------------------------------------------------------

/// Muat token dari disk. Dipanggil sekali saat aplikasi dimulai.
Future<void> muatToken() async {
  if (_sudahMuatToken) return;
  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString(_kunciToken);
  _sudahMuatToken = true;
}

/// Simpan token setelah login berhasil.
Future<void> simpanToken(String token) async {
  _token = token;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kunciToken, token);
}

/// Hapus token saat logout.
Future<void> hapusToken() async {
  _token = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kunciToken);
}

/// True kalau ada token tersimpan (belum tentu masih sah).
bool get sudahMasuk => _token != null;

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------

Uri _uri(String path, [Map<String, String>? query]) {
  final url = '$basisApi$prefiks$path';
  final uri = Uri.parse(url);
  if (query != null && query.isNotEmpty) {
    return uri.replace(queryParameters: query);
  }
  return uri;
}

Map<String, String> get _headers => {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
  if (_token != null) 'Authorization': 'Bearer $_token',
};

/// Menerjemahkan respons ke Map, atau melempar [GagalMuat].
Map<String, dynamic> _proses(http.Response respons) {
  if (respons.statusCode == 401) {
    // Token sudah tidak sah — paksa logout.
    hapusToken();
    throw const GagalMuat('Sesi berakhir. Silakan masuk kembali.');
  }

  final badan = respons.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(respons.body) as Map<String, dynamic>;

  if (respons.statusCode >= 200 && respons.statusCode < 300) {
    return badan;
  }

  // Pesan validasi Laravel: ambil yang pertama.
  if (respons.statusCode == 422 && badan.containsKey('errors')) {
    final errors = badan['errors'] as Map<String, dynamic>;
    final pesan = errors.values.first;
    final teks = pesan is List ? pesan.first.toString() : pesan.toString();
    throw GagalMuat(teks);
  }

  final pesan = badan['message'] as String? ?? 'Terjadi kesalahan.';
  throw GagalMuat(pesan);
}

/// Menerjemahkan respons daftar (Laravel resource collection).
List<dynamic> _prosesDaftar(http.Response respons) {
  if (respons.statusCode == 401) {
    hapusToken();
    throw const GagalMuat('Sesi berakhir. Silakan masuk kembali.');
  }

  if (respons.statusCode >= 200 && respons.statusCode < 300) {
    final badan = jsonDecode(respons.body);
    if (badan is List) return badan;
    // Kadang Laravel membungkus dalam `data`.
    if (badan is Map<String, dynamic> && badan.containsKey('data')) {
      return badan['data'] as List<dynamic>;
    }
    return [badan];
  }

  // Fallback ke _proses untuk mendapatkan pesan error.
  _proses(respons);
  return []; // Tidak akan tercapai.
}

final _timeout = const Duration(seconds: timeoutDetik);

// ---------------------------------------------------------------------------
// Metode HTTP publik
// ---------------------------------------------------------------------------

/// GET request.
Future<Map<String, dynamic>> get(
  String path, [
  Map<String, String>? query,
]) async {
  try {
    final respons = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(_timeout);
    return _proses(respons);
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}

/// GET request yang mengembalikan daftar.
Future<List<dynamic>> getDaftar(
  String path, [
  Map<String, String>? query,
]) async {
  try {
    final respons = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(_timeout);
    return _prosesDaftar(respons);
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}

/// POST request.
Future<Map<String, dynamic>> post(
  String path, [
  Map<String, dynamic>? body,
]) async {
  try {
    final respons = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _proses(respons);
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}

/// PUT request.
Future<Map<String, dynamic>> put(
  String path, [
  Map<String, dynamic>? body,
]) async {
  try {
    final respons = await http
        .put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _proses(respons);
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}

/// PATCH request.
Future<Map<String, dynamic>> patch(
  String path, [
  Map<String, dynamic>? body,
]) async {
  try {
    final respons = await http
        .patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _proses(respons);
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}

/// DELETE request.
Future<void> delete(String path) async {
  try {
    final respons = await http
        .delete(_uri(path), headers: _headers)
        .timeout(_timeout);
    if (respons.statusCode == 401) {
      hapusToken();
      throw const GagalMuat('Sesi berakhir. Silakan masuk kembali.');
    }
    if (respons.statusCode >= 300) {
      _proses(respons);
    }
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}

/// GET request mengembalikan raw bytes (misal berkas Excel).
Future<({Uint8List bytes, String? filename})> getBytes(
  String path, [
  Map<String, String>? query,
]) async {
  try {
    final respons = await http
        .get(_uri(path, query), headers: {
          'Accept':
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/octet-stream',
          if (_token != null) 'Authorization': 'Bearer $_token',
        })
        .timeout(_timeout);

    if (respons.statusCode == 401) {
      hapusToken();
      throw const GagalMuat('Sesi berakhir. Silakan masuk kembali.');
    }

    if (respons.statusCode >= 300) {
      _proses(respons);
    }

    String? filename;
    final disposition = respons.headers['content-disposition'];
    if (disposition != null && disposition.contains('filename=')) {
      final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
      if (match != null) filename = match.group(1);
    }

    return (bytes: respons.bodyBytes, filename: filename);
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}

/// POST multipart upload file.
Future<Map<String, dynamic>> uploadFile(
  String path,
  List<int> bytes,
  String filename, {
  String fieldName = 'file',
}) async {
  try {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    return _proses(response);
  } on SocketException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  } on http.ClientException {
    throw const GagalMuat('Tidak bisa terhubung ke server.');
  }
}
