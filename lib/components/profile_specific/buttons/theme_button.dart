import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../screens/profile_screen.dart';
import '../../../theme/app_theme.dart';
import '../../general/shinny_button.dart';

class ThemeButton extends StatelessWidget {
  const ThemeButton({
    super.key,
    required this.isDark,
    required this.widget,
  });

  final bool isDark;
  final ProfileScreen widget;

  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      onPressed: () {
        final targetMode =
        isDark ? AppThemeMode.light : AppThemeMode.dark;
        widget.themeController.setMode(targetMode);
      },
      text: isDark ? 'Modo claro' : 'Modo oscuro',
      icons: isDark?Icons.light_mode:Icons.dark_mode,
      width: 220,
      height: 48,
    );
  }
}
