import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Nomor WhatsApp CS Support default. Nomor ini dapat diubah langsung oleh pengguna.
const nomorWhatsAppCSDefault = '62895388770664';

/// Fungsi pembuka aplikasi WhatsApp secara langsung.
Future<void> bukaWhatsApp(
  BuildContext context, {
  String nomor = nomorWhatsAppCSDefault,
  String pesan =
      'Halo CS JualinAja, saya membutuhkan bantuan terkait aplikasi.',
}) async {
  final nomorBersih = nomor.replaceAll(RegExp(r'[^0-9]'), '');
  final textEncoded = Uri.encodeComponent(pesan);

  final uriApp = Uri.parse(
    'whatsapp://send?phone=$nomorBersih&text=$textEncoded',
  );
  final uriWeb = Uri.parse('https://wa.me/$nomorBersih?text=$textEncoded');

  try {
    // 1. Coba via scheme whatsapp://
    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp, mode: LaunchMode.externalApplication);
      return;
    }

    // 2. Fallback via wa.me (Buka via browser/WhatsApp)
    if (await canLaunchUrl(uriWeb)) {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      return;
    }

    // 3. Paksa peluncuran jika canLaunchUrl mengembalikan false di beberapa OS
    await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuka WhatsApp (+ $nomorBersih). Pastikan WhatsApp terpasang.',
            ),
          ),
        );
    }
  }
}
