import 'package:flutter/material.dart';
import 'app_gradients.dart';

ThemeData buildAppTheme(
  ColorScheme colorScheme,
  Brightness brightness, {
  AppGradientTheme? gradient,
}) {
  final TextTheme baseTextTheme = brightness == Brightness.dark
      ? Typography.whiteMountainView
      : Typography.blackMountainView;
  final tintedTextTheme = baseTextTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
  final textTheme = tintedTextTheme.copyWith(
    bodySmall: tintedTextTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    titleMedium: tintedTextTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
    ),
  );

  final borderRadius = BorderRadius.circular(15);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    // Hacemos el Scaffold transparente para que se vea el degradado de fondo
    scaffoldBackgroundColor: Colors.transparent,
    dividerColor: colorScheme.outlineVariant,
    disabledColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.65),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.secondary, width: 2),
      ),
    ),
    iconTheme: IconThemeData(color: colorScheme.onSurface),
    shadowColor: brightness == Brightness.dark
        ? Colors.black.withOpacity(0.65)
        : Colors.black.withOpacity(0.2),
    canvasColor: Colors.white,
    extensions: <ThemeExtension<dynamic>>[
      if (gradient != null) gradient,
    ],
  );
}
