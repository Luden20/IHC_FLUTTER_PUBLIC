# appihv – Guía rápida del proyecto

Este documento resume lo más importante: dónde se define la paleta de colores/tema y cómo está organizado el código.

## Paleta de colores y temas

- Paleta Light: `lib/theme/light_theme.dart:5` (clase `LightThemeColors`). Aquí están las constantes de color y el `ColorScheme` para el modo claro.
- Paleta Dark: `lib/theme/dark_theme.dart:5` (clase `DarkThemeColors`). Aquí están las constantes de color y el `ColorScheme` para el modo oscuro.
- Constructor de Theme: `lib/theme/theme_builder.dart:1`. La función `buildAppTheme` aplica tipografías, `AppBarTheme`, `ElevatedButtonTheme`, `InputDecorationTheme`, etc. a partir del `ColorScheme`.
- Resolución y control del tema: `lib/theme/app_theme.dart:7`. `AppTheme.resolve` devuelve el `ThemeData` según `AppThemeMode` y `AppThemeController` persiste la preferencia en `SharedPreferences`.
- Aplicación del tema: `lib/main.dart:95`. En el `MaterialApp` se asigna `theme: themeData` con el valor resuelto por `AppTheme`.

### Cómo cambiar colores o estilos

1. Edita las constantes en `LightThemeColors` y `DarkThemeColors` para actualizar colores base.
2. Si agregas un nuevo “rol” de color, añádelo en ambas paletas y mapea en su `ColorScheme` respectivo.
3. Ajusta estilos globales (tipografías, botones, inputs, app bar) en `lib/theme/theme_builder.dart`.
4. En los widgets, usa `Theme.of(context).colorScheme` y `Theme.of(context).textTheme` para mantener consistencia.

Ejemplos de uso en UI:

- `Theme.of(context).colorScheme.primary`
- `Theme.of(context).colorScheme.onSurfaceVariant`
- `Theme.of(context).textTheme.titleMedium`

Para alternar el tema en tiempo de ejecución: usa `AppThemeController.toggle()` (se guarda automáticamente).

## Estructura del proyecto (lib/)

- `lib/main.dart`: punto de entrada; configura `MaterialApp` y aplica el tema.
- `lib/theme/`: sistema de temas y paletas.
  - `app_theme.dart`: enum `AppThemeMode`, resolución del tema y controlador persistente.
  - `light_theme.dart`: paleta y `ColorScheme` del tema claro.
  - `dark_theme.dart`: paleta y `ColorScheme` del tema oscuro.
  - `theme_builder.dart`: construcción de `ThemeData` (estilos globales).
- `lib/screens/`: pantallas principales (home, join, create, profile, login, etc.).
- `lib/components/`: widgets reutilizables.
  - `general/`: componentes generales (inputs, botones, contenedores, etc.).
  - `event_specific/`: componentes específicos de eventos (galería, QR, etc.).
  - `login_specific/`: componentes relacionados al flujo de login/registro.
- `lib/service/`: servicios (permisos, red, PocketBase, place picker, background, etc.).
- `lib/dtos/`: DTOs y modelos de datos utilizados en la app.
- `lib/firebase_options.dart`: configuración generada de Firebase.
- `lib/screen_enums.dart`: enumeraciones de navegación entre pantallas.

## Notas rápidas

- Para agregar un nuevo estilo global (por ejemplo, `TextButtonTheme`), centralízalo en `theme_builder.dart`.
- Evita hardcodear colores en widgets: usa siempre `colorScheme` o `textTheme`.
- Si cambias nombres o roles de colores, mantén la paridad entre Light y Dark.
