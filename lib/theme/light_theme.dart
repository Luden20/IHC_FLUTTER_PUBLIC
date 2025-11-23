import 'package:flutter/material.dart';

import 'theme_builder.dart';
import 'app_gradients.dart';

class LightThemeColors {
  static const Color primary = Color(0xFF8A5DF8);               // Botones
  static const Color primary2 = Color(0xFFF97119);               // Botones
  static const Color secondary = Color(0xFF22272D);             // Titulos e iconos
  static const Color tertiary = Color(0xFF22272D);              // Flecha para regresar
  static const Color background = Color(0xFFF6F4FB);            //
  static const Color surface = Color(0xFFFFFFFF);               // Fondo de campos que no son de texto, Nav y lo de arriba
  static const Color surfaceVariant = Color(0xFFFFFFFF);        // Fondo de los formularios de texto
  static const Color primaryContainer = Color(0xFFFFD6EA);      // Color del medio del degradado
  static const Color secondaryContainerr = Color(0xFF201938);   // Color de arriba izquierda
  static const Color secondaryContainer = Color(0xFFCBF5F8);    //y fondo dela navbar
  static const Color tertiaryContainer = Color(0xFFE8DEFF);     // Color de abajo derecha
  static const Color outline = Color(0xFF707070);               // Outline de los formularios que no son de texto
  static const Color outlineVariant = Color(0xFF707070);        // Outline de los formularios de texto
  static const Color onPrimary = Colors.white;                  // Letras de los botones
  static const Color onSecondary = Color(0xFF002024);           // Color del ícono seleccionado en la nav
  static const Color onTertiary = Colors.white;                 //
  static const Color onSurface = Color(0xFF1F1C2C);             // Texto de arriba, nav bar seleccionado, y mapa incluido icono
  static const Color onSurfaceVariant = Color(0xFF5A5770);      // Texto de campos de texto, iconos y texto de nav bar no seleccionado
  static const Color onBackground = Color(0xFF1C1A27);          // Nombre en el Perfil
  static const Color error = Color(0xFFCB514A);                 //
  static const Color onError = Colors.white;                    //
  static const Color surfaceTint = tertiary;                    //
  static const Color scrim = Colors.black;                      //

  // Degradado (3 colores) para tema claro
  // static const Color gradientStart = secondaryContainer;
  // static const Color gradientMiddle = primaryContainer;
  // static const Color gradientEnd = tertiaryContainer;
  static const Color gradientStart = Color(0xFFBED8FF);
  static const Color gradientMiddle = Color(0xFFFFFFFF);
  static const Color gradientEnd = Color(0xFFE9DBFF);


  static const ColorScheme colorScheme = ColorScheme.light(
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

class LightAppTheme {
  static ThemeData get data => buildAppTheme(
        LightThemeColors.colorScheme,
        Brightness.light,
        gradient: const AppGradientTheme(
          start: LightThemeColors.gradientStart,
          middle: LightThemeColors.gradientMiddle,
          end: LightThemeColors.gradientEnd,
          begin: Alignment.topLeft,
          alignEnd: Alignment.bottomRight,
        ),
      );
}
