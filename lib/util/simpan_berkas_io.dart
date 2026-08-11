import 'dart:io';
import 'dart:typed_data';

/// Simpan berkas ke folder Download / Unduhan perangkat publik agar muncul
/// di File Manager (Pengelola Berkas).
Future<String> simpanBerkasKePerangkat(Uint8List bytes, String namaBerkas) async {
  Directory? targetDir;

  if (Platform.isAndroid) {
    final downloadPath = Directory('/storage/emulated/0/Download');
    if (await downloadPath.exists()) {
      targetDir = downloadPath;
    } else {
      final sdcardDownload = Directory('/sdcard/Download');
      if (await sdcardDownload.exists()) {
        targetDir = sdcardDownload;
      }
    }
  } else if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      final winDownload = Directory('$userProfile\\Downloads');
      if (await winDownload.exists()) {
        targetDir = winDownload;
      }
    }
  } else if (Platform.isMacOS || Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final macDownload = Directory('$home/Downloads');
      if (await macDownload.exists()) {
        targetDir = macDownload;
      }
    }
  }

  // Fallback ke systemTemp jika lokasi unduhan publik tidak ditemukan
  targetDir ??= Directory.systemTemp;

  final berkas = File('${targetDir.path}/$namaBerkas');
  await berkas.writeAsBytes(bytes);
  return berkas.path;
}
