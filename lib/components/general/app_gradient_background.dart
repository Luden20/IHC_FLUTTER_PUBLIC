import 'package:flutter/material.dart';
import 'package:appihv/theme/app_gradients.dart';

class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppGradientTheme>();
    final gradient = ext?.toLinearGradient() ??
        const LinearGradient(colors: [Colors.black, Colors.black, Colors.black]);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}

