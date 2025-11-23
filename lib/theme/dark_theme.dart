import 'package:flutter/material.dart';

import 'theme_builder.dart';
import 'app_gradients.dart';

class DarkThemeColors {
  static const Color primary = Color(0xFF8B5CF8);               // Botones
  static const Color secondary = Color(0xFFFFFFFF);             // Titulos e iconos
  static const Color tertiary = Color(0xFFF97119);              // Flecha para regresar y boton secundario
  static const Color background = Color(0xFF0D0D1F);            //
  static const Color surface = Color(0xFF17162C);               // Fondo de campos que no son de texto, Nav y lo de arriba
  static const Color surfaceVariant = Color(0xFF152032);        // Fondo de los formularios de texto
  static const Color primaryContainer = Color(0xFF0F172A);      // Color del medio del degradado
  static const Color secondaryContainerr = Color(0xFF2E1B3B);    // Color de arriba izquierda
  static const Color secondaryContainer = Color(0xFFF97119);    //y fondo dela navbar
  static const Color tertiaryContainer = Color(0xFF0B3336);     // Color de abajo derecha
  static const Color outline = Color(0xFF7474AF);               // Outline de los formularios que no son de texto
  static const Color outlineVariant = Color(0xFF7474AF);        // Outline de los formularios de texto
  static const Color onPrimary = Color(0xFFEEEEEE);             // Letras de los botones
  static const Color onSecondary = Color(0xFFFFFFFF);           // Color del ícono seleccionado en la nav
  static const Color onTertiary = Colors.white;                 //
  static const Color onSurface = Color(0xFFE6E6F4);             // Texto de arriba, nav bar seleccionado, y mapa incluido icono
  static const Color onSurfaceVariant = Color(0xFFFFFFFF);      // Texto de campos de texto, iconos y texto de nav bar no seleccionado
  static const Color onBackground = Color(0xFFB091FF);          // Nombre en el Perfil
  static const Color error = Color(0xFFFF6B6B);                 //
  static const Color onError = Colors.white;                    //
  static const Color surfaceTint = tertiary;                    //
  static const Color scrim = Colors.black;                      //

  // Degradado (3 colores) para tema oscuro
  static const Color gradientStart = secondaryContainerr;
  static const Color gradientMiddle = primaryContainer;
  static const Color gradientEnd = tertiaryContainer;

  static const ColorScheme colorScheme = ColorScheme.dark(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    background: background,
    onBackground: onBackground,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    surfaceTint: surfaceTint,
    error: error,
    onError: onError,
    outline: outline,
    outlineVariant: outlineVariant,
    scrim: scrim,
  );
}

class DarkAppTheme {
  static ThemeData get data => buildAppTheme(
        DarkThemeColors.colorScheme,
        Brightness.dark,
        gradient: const AppGradientTheme(
          start: DarkThemeColors.gradientStart,
          middle: DarkThemeColors.gradientMiddle,
          end: DarkThemeColors.gradientEnd,
          begin: Alignment.topLeft,
          alignEnd: Alignment.bottomRight,
        ),
      );
}
