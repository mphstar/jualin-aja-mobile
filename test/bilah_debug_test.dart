import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/backdoor.dart';
import 'package:mobile/widgets/bilah_debug.dart';

/// Halaman ber-state — dipakai untuk membuktikan `State`-nya tidak pernah
/// diganti saat mode debug dinyalakan.
class _Halaman extends StatefulWidget {
  const _Halaman();

  @override
  State<_Halaman> createState() => _HalamanState();
}

class _HalamanState extends State<_Halaman> {
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('isi halaman')));
}

const _teksBilah = 'MODE DEBUG · BACKDOOR';

/// Berapa `Expanded` di antara akar aplikasi dan halamannya.
///
/// Harus **nol**, baik saat mode debug mati maupun hidup. Bentuk lama
/// membungkus halaman dengan `Column(Expanded)` hanya saat mode debug hidup,
/// jadi angkanya berubah dari 0 ke 1 — `Navigator` yang memegang `GlobalKey`
/// berpindah kedalaman, dan `Expanded` itulah yang Flutter sebut sebagai
/// penyebab `RenderBox was not laid out`.
int _jumlahExpanded(WidgetTester tester) => tester
    .widgetList(
      find.ancestor(
        of: find.byType(_Halaman),
        matching: find.byType(Expanded),
      ),
    )
    .length;

Future<void> _pasang(WidgetTester tester, GlobalKey<NavigatorState> kunci) =>
    tester.pumpWidget(
      MaterialApp(
        navigatorKey: kunci,
        builder: (context, anak) => BilahDebug(anak: anak!),
        home: const _Halaman(),
      ),
    );

void main() {
  tearDown(() => modeDebug.value = false);

  testWidgets('bentuk pohonnya tidak berubah saat mode debug dinyalakan', (
    tester,
  ) async {
    // Patahan aslinya (`RenderBox was not laid out` disusul
    // `!semantics.parentDataDirty`) datang dari mesin render dan semantik yang
    // sungguhan, jadi ia tidak selalu muncul di `flutter test`. Yang bisa dan
    // perlu dijaga di sini adalah sebabnya: tidak ada satu pun widget pengatur
    // tata letak yang disisipkan di atas `Navigator`, dan susunan widgetnya
    // tetap.
    final kunci = GlobalKey<NavigatorState>();
    await _pasang(tester, kunci);

    final navigatorSebelum = kunci.currentState;
    final stateSebelum = tester.state(find.byType(_Halaman));
    expect(_jumlahExpanded(tester), 0);
    expect(find.text(_teksBilah), findsNothing);

    modeDebug.value = true;
    await tester.pumpAndSettle();

    expect(find.text(_teksBilah), findsOneWidget);
    expect(_jumlahExpanded(tester), 0);
    expect(kunci.currentState, same(navigatorSebelum));
    expect(tester.state(find.byType(_Halaman)), same(stateSebelum));

    modeDebug.value = false;
    await tester.pumpAndSettle();

    expect(find.text(_teksBilah), findsNothing);
    expect(_jumlahExpanded(tester), 0);
    expect(kunci.currentState, same(navigatorSebelum));
    expect(tester.state(find.byType(_Halaman)), same(stateSebelum));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bilahnya melayang, tidak memangkas tinggi halaman', (
    tester,
  ) async {
    // Bilah yang menumpuk tinggi memangkas kotak yang benar-benar tersedia
    // tanpa memperbarui `MediaQuery`, sementara `Scaffold` menghitung sisipan
    // papan ketik dari `MediaQuery`. Dua angka itu lalu saling bertentangan.
    await _pasang(tester, GlobalKey<NavigatorState>());

    final tinggi = tester.getSize(find.byType(_Halaman)).height;

    modeDebug.value = true;
    await tester.pumpAndSettle();

    expect(find.text(_teksBilah), findsOneWidget);
    expect(tester.getSize(find.byType(_Halaman)).height, tinggi);
  });

  testWidgets('bilahnya disembunyikan, bukan dibuang dari pohon', (
    tester,
  ) async {
    // `Offstage` menahan widgetnya tetap di pohon dan hanya berhenti
    // menggambarnya. Ini yang membuat bentuk pohonnya tidak perlu berubah.
    // Bentuk lama tidak punya `Offstage` sama sekali saat mode debug mati.
    await _pasang(tester, GlobalKey<NavigatorState>());

    expect(find.text(_teksBilah, skipOffstage: false), findsOneWidget);
    expect(find.text(_teksBilah), findsNothing);

    modeDebug.value = true;
    await tester.pumpAndSettle();

    expect(find.text(_teksBilah, skipOffstage: false), findsOneWidget);
    expect(find.text(_teksBilah), findsOneWidget);
  });
}
