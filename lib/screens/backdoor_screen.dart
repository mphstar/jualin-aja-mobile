import 'package:flutter/material.dart';

import '../data/backdoor.dart';
import '../data/config.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/kartu.dart';

/// Layar backdoor debug: ganti basis API, mode debug, dan melihat log error.
///
/// Dibuka dari onboarding dengan mengetuk logo sepuluh kali lalu memasukkan
/// kata sandi ([kataSandiBackdoor]).
class BackdoorScreen extends StatefulWidget {
  const BackdoorScreen({super.key});

  @override
  State<BackdoorScreen> createState() => _BackdoorScreenState();
}

class _BackdoorScreenState extends State<BackdoorScreen> {
  final _urlController = TextEditingController();
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = basisApi;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _beriTahu(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan)),
    );
  }

  Future<void> _simpanUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _beriTahu('URL tidak boleh kosong.');
      return;
    }
    setState(() => _menyimpan = true);
    await simpanBasisApi(url);
    if (!mounted) return;
    setState(() => _menyimpan = false);
    _beriTahu('Basis API tersimpan.');
  }

  Future<void> _pulihkanUrl() async {
    await pulihkanBasisApi();
    if (!mounted) return;
    setState(() => _urlController.text = basisApi);
    _beriTahu('Basis API kembali ke bawaan.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backdoor Debug')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(Jarak.md),
          children: [
            Text(
              'Backdoor ini untuk debugging. Jangan sebarkan kata sandinya, '
              'dan jangan biarkan terbuka di perangkat pelanggan.',
              style: context.teks.bodySmall?.copyWith(
                color: context.warna.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Jarak.md),

            JudulBagian('Mode debug'),
            KartuDaftar(anak: [
              ValueListenableBuilder<bool>(
                valueListenable: modeDebug,
                builder: (context, aktif, _) => SwitchListTile(
                  title: const Text('Aktifkan mode debug'),
                  subtitle: const Text(
                    'Menampilkan bilah penanda di atas aplikasi.',
                  ),
                  value: aktif,
                  onChanged: setModeDebug,
                ),
              ),
            ]),
            const SizedBox(height: Jarak.md),

            JudulBagian('Basis API'),
            KartuDaftar(anak: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Jarak.xs,
                  Jarak.xs,
                  Jarak.xs,
                  0,
                ),
                child: TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _simpanUrl(),
                  decoration: const InputDecoration(
                    labelText: 'URL dasar API',
                    helperText: 'Contoh: https://xxx.ngrok-free.app',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Jarak.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _menyimpan ? null : _simpanUrl,
                        child: const Text('Simpan URL'),
                      ),
                    ),
                    const SizedBox(width: Jarak.xs2),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pulihkanUrl,
                        child: const Text('Kembalikan bawaan'),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: Jarak.md),

            JudulBagian(
              'Log error',
              aksi: ValueListenableBuilder<List<EntriLog>>(
                valueListenable: logError,
                builder: (context, daftar, _) => daftar.isEmpty
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: bersihkanLog,
                        child: const Text('Bersihkan'),
                      ),
              ),
            ),
            ValueListenableBuilder<List<EntriLog>>(
              valueListenable: logError,
              builder: (context, daftar, _) {
                if (daftar.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(Jarak.md),
                    decoration: BoxDecoration(
                      color: context.warna.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(Lengkung.panel),
                      border: Border.all(color: context.warna.outline),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: context.warna.onSurfaceVariant,
                        ),
                        const SizedBox(height: Jarak.xs2),
                        Text(
                          'Belum ada error tercatat.',
                          textAlign: TextAlign.center,
                          style: context.teks.bodyMedium?.copyWith(
                            color: context.warna.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final entri in daftar.reversed) _EntriLog(entri: entri),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu kartu entri log error.
class _EntriLog extends StatelessWidget {
  const _EntriLog({required this.entri});

  final EntriLog entri;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Jarak.xs2),
      padding: const EdgeInsets.all(Jarak.xs),
      decoration: BoxDecoration(
        color: context.warna.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Lengkung.kontrol),
        border: Border.all(color: context.warna.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: context.warna.error),
              const SizedBox(width: Jarak.xs2),
              Expanded(
                child: Text(
                  entri.sumber,
                  style: context.teks.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                relatif(entri.waktu),
                style: context.teks.labelSmall?.copyWith(
                  color: context.warna.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Jarak.xs2),
          Text(
            entri.pesan,
            style: context.teks.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          if (entri.stack != null) ...[
            const SizedBox(height: Jarak.xs2),
            Text(
              entri.stack!,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: context.teks.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: context.warna.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
