import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Warna di luar [ColorScheme] yang tetap harus ikut mode terang/gelap.
///
/// Alasan ia ada: Material menyediakan slot untuk primer, permukaan, dan
/// error — tapi tidak untuk "sukses", "peringatan", atau "permukaan fokus".
/// Menaruhnya di sini membuat widget tidak pernah perlu bertanya
/// `if (gelap)`; mereka cuma membaca `context.aksen`.
@immutable
class Aksen extends ThemeExtension<Aksen> {
  const Aksen({
    required this.fokus,
    required this.atasFokus,
    required this.atasFokusRedup,
    required this.kartuAlt,
    required this.isian,
    required this.garisRedup,
    required this.sukses,
    required this.suksesLembut,
    required this.peringatan,
    required this.peringatanLembut,
    required this.bahaya,
    required this.bahayaLembut,
    required this.info,
    required this.infoLembut,
    required this.bayanganKartu,
    required this.bayanganMengambang,
  });

  final Color fokus;
  final Color atasFokus;
  final Color atasFokusRedup;
  final Color kartuAlt;
  final Color isian;
  final Color garisRedup;

  final Color sukses;
  final Color suksesLembut;
  final Color peringatan;
  final Color peringatanLembut;
  final Color bahaya;
  final Color bahayaLembut;
  final Color info;
  final Color infoLembut;

  final List<BoxShadow> bayanganKartu;
  final List<BoxShadow> bayanganMengambang;

  static const terang = Aksen(
    fokus: WarnaTerang.fokus,
    atasFokus: WarnaTerang.atasFokus,
    atasFokusRedup: WarnaTerang.atasFokusRedup,
    kartuAlt: WarnaTerang.kartuAlt,
    isian: WarnaTerang.isian,
    garisRedup: WarnaTerang.garisRedup,
    sukses: WarnaTerang.sukses,
    suksesLembut: WarnaTerang.suksesLembut,
    peringatan: WarnaTerang.peringatan,
    peringatanLembut: WarnaTerang.peringatanLembut,
    bahaya: WarnaTerang.bahaya,
    bahayaLembut: WarnaTerang.bahayaLembut,
    info: WarnaTerang.info,
    infoLembut: WarnaTerang.infoLembut,
    bayanganKartu: Bayangan.kartu,
    bayanganMengambang: Bayangan.mengambang,
  );

  static const gelap = Aksen(
    fokus: WarnaGelap.fokus,
    atasFokus: WarnaGelap.atasFokus,
    atasFokusRedup: WarnaGelap.atasFokusRedup,
    kartuAlt: WarnaGelap.kartuAlt,
    isian: WarnaGelap.isian,
    garisRedup: WarnaGelap.garisRedup,
    sukses: WarnaGelap.sukses,
    suksesLembut: WarnaGelap.suksesLembut,
    peringatan: WarnaGelap.peringatan,
    peringatanLembut: WarnaGelap.peringatanLembut,
    bahaya: WarnaGelap.bahaya,
    bahayaLembut: WarnaGelap.bahayaLembut,
    info: WarnaGelap.info,
    infoLembut: WarnaGelap.infoLembut,
    bayanganKartu: Bayangan.kartu,
    bayanganMengambang: Bayangan.mengambang,
  );

  @override
  Aksen copyWith({
    Color? fokus,
    Color? atasFokus,
    Color? atasFokusRedup,
    Color? kartuAlt,
    Color? isian,
    Color? garisRedup,
    Color? sukses,
    Color? suksesLembut,
    Color? peringatan,
    Color? peringatanLembut,
    Color? bahaya,
    Color? bahayaLembut,
    Color? info,
    Color? infoLembut,
    List<BoxShadow>? bayanganKartu,
    List<BoxShadow>? bayanganMengambang,
  }) {
    return Aksen(
      fokus: fokus ?? this.fokus,
      atasFokus: atasFokus ?? this.atasFokus,
      atasFokusRedup: atasFokusRedup ?? this.atasFokusRedup,
      kartuAlt: kartuAlt ?? this.kartuAlt,
      isian: isian ?? this.isian,
      garisRedup: garisRedup ?? this.garisRedup,
      sukses: sukses ?? this.sukses,
      suksesLembut: suksesLembut ?? this.suksesLembut,
      peringatan: peringatan ?? this.peringatan,
      peringatanLembut: peringatanLembut ?? this.peringatanLembut,
      bahaya: bahaya ?? this.bahaya,
      bahayaLembut: bahayaLembut ?? this.bahayaLembut,
      info: info ?? this.info,
      infoLembut: infoLembut ?? this.infoLembut,
      bayanganKartu: bayanganKartu ?? this.bayanganKartu,
      bayanganMengambang: bayanganMengambang ?? this.bayanganMengambang,
    );
  }

  @override
  Aksen lerp(ThemeExtension<Aksen>? lain, double t) {
    if (lain is! Aksen) return this;
    return Aksen(
      fokus: Color.lerp(fokus, lain.fokus, t)!,
      atasFokus: Color.lerp(atasFokus, lain.atasFokus, t)!,
      atasFokusRedup: Color.lerp(atasFokusRedup, lain.atasFokusRedup, t)!,
      kartuAlt: Color.lerp(kartuAlt, lain.kartuAlt, t)!,
      isian: Color.lerp(isian, lain.isian, t)!,
      garisRedup: Color.lerp(garisRedup, lain.garisRedup, t)!,
      sukses: Color.lerp(sukses, lain.sukses, t)!,
      suksesLembut: Color.lerp(suksesLembut, lain.suksesLembut, t)!,
      peringatan: Color.lerp(peringatan, lain.peringatan, t)!,
      peringatanLembut: Color.lerp(peringatanLembut, lain.peringatanLembut, t)!,
      bahaya: Color.lerp(bahaya, lain.bahaya, t)!,
      bahayaLembut: Color.lerp(bahayaLembut, lain.bahayaLembut, t)!,
      info: Color.lerp(info, lain.info, t)!,
      infoLembut: Color.lerp(infoLembut, lain.infoLembut, t)!,
      bayanganKartu: t < 0.5 ? bayanganKartu : lain.bayanganKartu,
      bayanganMengambang: t < 0.5
          ? bayanganMengambang
          : lain.bayanganMengambang,
    );
  }
}

/// Pintasan baca tema. `context.warna.primary` jauh lebih enak dibaca daripada
/// `Theme.of(context).colorScheme.primary` — dan panjangnya yang bertele-tele
/// itulah yang biasanya membuat orang menyerah lalu menulis warna mentah.
extension PintasTema on BuildContext {
  ColorScheme get warna => Theme.of(this).colorScheme;
  TextTheme get teks => Theme.of(this).textTheme;
  Aksen get aksen => Theme.of(this).extension<Aksen>()!;
}

abstract final class TemaAplikasi {
  static ThemeData terang() => _susun(
    kecerahan: Brightness.light,
    aksen: Aksen.terang,
    skema: const ColorScheme(
      brightness: Brightness.light,
      primary: WarnaTerang.utama,
      onPrimary: WarnaTerang.atasUtama,
      primaryContainer: WarnaTerang.kartuAlt,
      onPrimaryContainer: WarnaTerang.tinta,
      secondary: WarnaTerang.tintaRedup,
      onSecondary: WarnaTerang.kertas,
      tertiary: WarnaTerang.tinta,
      onTertiary: WarnaTerang.kertas,
      error: WarnaTerang.bahaya,
      onError: WarnaTerang.atasBahaya,
      errorContainer: WarnaTerang.bahayaLembut,
      onErrorContainer: WarnaTerang.bahaya,
      surface: WarnaTerang.kertas,
      onSurface: WarnaTerang.tinta,
      onSurfaceVariant: WarnaTerang.tintaRedup,
      surfaceContainerLowest: WarnaTerang.kartu,
      surfaceContainerLow: WarnaTerang.kartu,
      surfaceContainer: WarnaTerang.kartuAlt,
      surfaceContainerHigh: WarnaTerang.kartuAlt,
      surfaceContainerHighest: WarnaTerang.isian,
      outline: WarnaTerang.garis,
      outlineVariant: WarnaTerang.garisRedup,
      inverseSurface: WarnaTerang.fokus,
      onInverseSurface: WarnaTerang.atasFokus,
      shadow: WarnaTerang.bayang,
      scrim: WarnaTerang.bayang,
    ),
  );

  static ThemeData gelap() => _susun(
    kecerahan: Brightness.dark,
    aksen: Aksen.gelap,
    skema: const ColorScheme(
      brightness: Brightness.dark,
      primary: WarnaGelap.utama,
      onPrimary: WarnaGelap.atasUtama,
      primaryContainer: WarnaGelap.kartuAlt,
      onPrimaryContainer: WarnaGelap.tinta,
      secondary: WarnaGelap.tintaRedup,
      onSecondary: WarnaGelap.kertas,
      tertiary: WarnaGelap.tinta,
      onTertiary: WarnaGelap.kertas,
      error: WarnaGelap.bahaya,
      onError: WarnaGelap.atasBahaya,
      errorContainer: WarnaGelap.bahayaLembut,
      onErrorContainer: WarnaGelap.bahaya,
      surface: WarnaGelap.kertas,
      onSurface: WarnaGelap.tinta,
      onSurfaceVariant: WarnaGelap.tintaRedup,
      surfaceContainerLowest: WarnaGelap.kartu,
      surfaceContainerLow: WarnaGelap.kartu,
      surfaceContainer: WarnaGelap.kartuAlt,
      surfaceContainerHigh: WarnaGelap.kartuAlt,
      surfaceContainerHighest: WarnaGelap.kartuAlt,
      outline: WarnaGelap.garis,
      outlineVariant: WarnaGelap.garisRedup,
      inverseSurface: WarnaGelap.fokus,
      onInverseSurface: WarnaGelap.atasFokus,
      shadow: WarnaGelap.bayang,
      scrim: WarnaGelap.bayang,
    ),
  );

  static ThemeData _susun({
    required ColorScheme skema,
    required Aksen aksen,
    required Brightness kecerahan,
  }) {
    final dasar = ThemeData(
      useMaterial3: true,
      brightness: kecerahan,
      colorScheme: skema,
      scaffoldBackgroundColor: skema.surface,
    );

    final teks = GoogleFonts.figtreeTextTheme(
      dasar.textTheme,
    ).apply(bodyColor: skema.onSurface, displayColor: skema.onSurface);

    return dasar.copyWith(
      extensions: [aksen],

      // Judul dirapatkan; teks badan dibiarkan apa adanya. Merapatkan teks
      // badan justru menurunkan keterbacaan pada ukuran kecil.
      textTheme: teks.copyWith(
        displaySmall: teks.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: kerapatanJudul(36),
          height: 1.08,
        ),
        headlineLarge: teks.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: kerapatanJudul(32),
        ),
        headlineMedium: teks.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: kerapatanJudul(28),
        ),
        headlineSmall: teks.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: kerapatanJudul(24),
        ),
        titleLarge: teks.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: kerapatanJudul(22),
        ),
        titleMedium: teks.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: teks.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelSmall: teks.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: skema.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: skema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: teks.titleLarge?.copyWith(
          color: skema.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: kerapatanJudul(22),
        ),
      ),

      cardTheme: CardThemeData(
        color: skema.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Lengkung.panel),
          side: BorderSide(color: skema.outline),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: skema.outline,
        thickness: 1,
        space: 1,
      ),

      // 52 px, bukan 40. Tombol ini ditekan sambil berdiri, sering dengan satu
      // tangan, kadang oleh orang yang sedang ditunggu pelanggan.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: Jarak.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Lengkung.kontrol),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: skema.onSurface,
          side: BorderSide(color: skema.outline),
          padding: const EdgeInsets.symmetric(horizontal: Jarak.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Lengkung.kontrol),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: skema.onSurface,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: skema.onSurfaceVariant),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: skema.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Jarak.sm,
          vertical: Jarak.xs,
        ),
        hintStyle: teks.bodyMedium?.copyWith(color: skema.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          borderSide: BorderSide(color: skema.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          borderSide: BorderSide(color: skema.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          borderSide: BorderSide(color: skema.onSurface, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          borderSide: BorderSide(color: skema.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
          borderSide: BorderSide(color: skema.error, width: 1.5),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: skema.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: skema.surfaceContainerHigh,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => teks.labelMedium?.copyWith(
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected)
                ? skema.onSurface
                : skema.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? skema.onSurface
                : skema.onSurfaceVariant,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: skema.surfaceContainerLowest,
        indicatorColor: skema.surfaceContainerHigh,
        selectedIconTheme: IconThemeData(size: 24, color: skema.onSurface),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: skema.onSurfaceVariant,
        ),
        selectedLabelTextStyle: teks.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: skema.onSurface,
        ),
        unselectedLabelTextStyle: teks.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: skema.onSurfaceVariant,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: skema.onSurface,
        unselectedLabelColor: skema.onSurfaceVariant,
        indicatorColor: skema.onSurface,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: skema.outline,
        labelStyle: teks.titleSmall,
        unselectedLabelStyle: teks.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),

      // Toast ringkas, bukan perayaan. Sama seperti panel web.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: aksen.fokus,
        contentTextStyle: teks.bodyMedium?.copyWith(color: aksen.atasFokus),
        actionTextColor: aksen.atasFokus,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Lengkung.kontrol),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: skema.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Lengkung.panel),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: skema.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Lengkung.panel),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: skema.onSurface,
        linearTrackColor: aksen.isian,
        circularTrackColor: aksen.isian,
      ),
    );
  }
}
