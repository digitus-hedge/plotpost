import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themePreferenceKey = 'plotpost_theme_mode';

final ValueNotifier<ThemeMode> plotPostThemeMode = ValueNotifier(
  ThemeMode.system,
);

/// Loads the user's saved theme preference before the app is displayed.
Future<void> loadPlotPostThemePreference() async {
  final preferences = await SharedPreferences.getInstance();
  final savedMode = preferences.getString(_themePreferenceKey);

  switch (savedMode) {
    case 'light':
      plotPostThemeMode.value = ThemeMode.light;
      break;
    case 'dark':
      plotPostThemeMode.value = ThemeMode.dark;
      break;
    case 'system':
    default:
      plotPostThemeMode.value = ThemeMode.system;
  }
}

/// Updates the app theme immediately and stores the selection for next launch.
Future<void> setPlotPostThemeMode(ThemeMode mode) async {
  plotPostThemeMode.value = mode;
  final preferences = await SharedPreferences.getInstance();
  final value = switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
  await preferences.setString(_themePreferenceKey, value);
}

Color plotPostTextAccent(BuildContext context, Color accentColor) =>
    accentColor;

ThemeData? _cachedLightTheme;
ThemeData? _cachedDarkTheme;

ThemeData buildPlotPostTheme(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return _cachedDarkTheme ??= _createTheme(Brightness.dark);
  } else {
    return _cachedLightTheme ??= _createTheme(Brightness.light);
  }
}

ThemeData _createTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  // Modern Royal Sapphire Color Palette
  const primarySapphire = Color(0xFF2563EB); // Royal Sapphire Blue
  const primarySapphireLight = Color(0xFF3B82F6); // Vibrant Electric Blue for Dark Mode
  const secondaryAmber = Color(0xFFD97706); // Warm Gold Accent
  const secondaryAmberLight = Color(0xFFF59E0B);
  const accentBlue = Color(0xFF0284C7); // Coastal Blue Accent

  // Dark Mode Surfaces (Midnight Obsidian)
  const darkBackground = Color(0xFF0B0F19); // Rich Slate Black
  const darkSurface = Color(0xFF111827); // Dark Slate Surface
  const darkCard = Color(0xFF1F2937); // Card Background
  const darkField = Color(0xFF1F2937); // Input Field Fill
  const darkBorder = Color(0xFF374151); // Divider & Border

  // Light Mode Surfaces (Clean Porcelain)
  const lightBackground = Color(0xFFF8FAFC); // Soft Slate White
  const lightSurface = Color(0xFFFFFFFF); // Pure White Surface
  const lightCard = Color(0xFFFFFFFF); // Pure White Card
  const lightField = Color(0xFFF1F5F9); // Light Input Field
  const lightBorder = Color(0xFFE2E8F0); // Subtle Slate Border

  final primaryColor = dark ? primarySapphireLight : primarySapphire;
  final secondaryColor = dark ? secondaryAmberLight : secondaryAmber;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: secondaryColor,
    onSecondary: Colors.white,
    tertiary: accentBlue,
    onTertiary: Colors.white,
    error: const Color(0xFFEF4444),
    onError: Colors.white,
    surface: dark ? darkSurface : lightSurface,
    onSurface: dark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A),
    onSurfaceVariant: dark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
    outline: dark ? darkBorder : lightBorder,
    outlineVariant: dark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
    shadow: const Color(0x1F000000),
    scrim: Colors.black,
    inverseSurface: dark ? const Color(0xFFF9FAFB) : darkSurface,
    onInverseSurface: dark ? darkBackground : const Color(0xFFF9FAFB),
    inversePrimary: primaryColor,
    surfaceTint: Colors.transparent,
  );

  final bg = dark ? darkBackground : lightBackground;
  final fieldColor = dark ? darkField : lightField;
  final border = dark ? darkBorder : lightBorder;
  final card = dark ? darkCard : lightCard;

  // Base TextTheme using Google Fonts - Plus Jakarta Sans
  final baseTextTheme = dark
      ? Typography.material2021().white
      : Typography.material2021().black;

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: scheme.onSurface,
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: scheme.onSurface,
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: scheme.onSurface,
    ),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: scheme.onSurface,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: scheme.onSurface,
    ),
    headlineSmall: GoogleFonts.plusJakartaSans(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: scheme.onSurface,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: scheme.onSurface,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
      color: scheme.onSurface,
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: scheme.onSurfaceVariant,
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: scheme.onSurfaceVariant,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    visualDensity: VisualDensity.standard,
    canvasColor: bg,
    cardColor: card,
    dividerColor: border,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.3,
      ),
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
    cardTheme: CardThemeData(
      color: card,
      elevation: dark ? 0 : 1.5,
      shadowColor: dark ? Colors.transparent : const Color(0x0F000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldColor,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: scheme.onSurfaceVariant,
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: scheme.onSurfaceVariant,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? darkField : lightField,
      selectedColor: primaryColor.withValues(alpha: dark ? 0.25 : 0.12),
      disabledColor: dark ? darkSurface : const Color(0xFFF1F5F9),
      side: BorderSide(color: border),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: dark ? darkSurface : lightSurface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      selectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 4,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? darkSurface : lightSurface,
      indicatorColor: primaryColor.withValues(alpha: dark ? 0.22 : 0.14),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.plusJakartaSans(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? darkSurface : lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? darkSurface : lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
      contentTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
    ),
  );
}
