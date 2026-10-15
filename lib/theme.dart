import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta tirada da logo: traço verde-mata sobre papel creme.
class Cores {
  static const mata = Color(
    0xFF0D3125,
  ); // traço da logo: texto, contornos, barra
  static const musgo = Color(0xFF3E6B48); // folhas
  static const papel = Color(0xFFF7F3E8); // fundo da logo
  static const papelEscuro = Color(0xFFEDE6D3); // áreas de destaque suave
  static const tomate = Color(0xFFC2502F); // preço e ação principal
  static const colheita = Color(0xFFD9A23B); // selos (orgânico, novidade)
  static const whatsapp = Color(0xFF1FA855);
}

// Público: feirantes e clientes de todas as idades -> letra grande e botões grandes.
ThemeData temaNossoQuintal() {
  final corpo = GoogleFonts.nunitoTextTheme().apply(
    bodyColor: Cores.mata,
    displayColor: Cores.mata,
  );
  final titulo = GoogleFonts.loraTextTheme();
  final contorno = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(color: Cores.mata, width: 1.4),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Cores.mata,
      primary: Cores.mata,
      onPrimary: Cores.papel,
      secondary: Cores.tomate,
      onSecondary: Colors.white,
      tertiary: Cores.colheita,
      surface: Cores.papel,
      onSurface: Cores.mata,
    ),
    scaffoldBackgroundColor: Cores.papel,
    textTheme: corpo.copyWith(
      headlineLarge: titulo.headlineLarge?.copyWith(
        color: Cores.mata,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: titulo.headlineMedium?.copyWith(
        color: Cores.mata,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: titulo.headlineSmall?.copyWith(
        color: Cores.mata,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: titulo.titleLarge?.copyWith(
        color: Cores.mata,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: corpo.bodyLarge?.copyWith(fontSize: 18),
      bodyMedium: corpo.bodyMedium?.copyWith(fontSize: 16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Cores.papel,
      foregroundColor: Cores.mata,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Cores.mata,
      ),
      shape: const Border(bottom: BorderSide(color: Cores.mata, width: 1.2)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contorno,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Cores.tomate,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(64, 56),
        textStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Cores.mata,
        minimumSize: const Size(64, 56),
        side: const BorderSide(color: Cores.mata, width: 1.4),
        textStyle: GoogleFonts.nunito(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Cores.mata,
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(fontSize: 17),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Cores.mata, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Cores.musgo, width: 2.2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Cores.mata,
      labelStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Cores.mata,
      ),
      secondaryLabelStyle: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Cores.papel,
      ),
      side: const BorderSide(color: Cores.mata, width: 1.2),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Cores.mata,
      unselectedLabelColor: Cores.musgo,
      indicatorColor: Cores.tomate,
      labelStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Cores.musgo : null,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Cores.mata,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(fontSize: 16, color: Cores.papel),
    ),
    dividerTheme: const DividerThemeData(
      color: Cores.papelEscuro,
      thickness: 1.2,
    ),
  );
}
