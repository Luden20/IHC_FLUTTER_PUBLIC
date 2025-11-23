import 'package:flutter/material.dart';

/// App-wide 3‑color gradient configured by theme.
class AppGradientTheme extends ThemeExtension<AppGradientTheme> {
  final Color start;
  final Color middle;
  final Color end;
  final Alignment begin;
  final Alignment alignEnd;

  const AppGradientTheme({
    required this.start,
    required this.middle,
    required this.end,
    this.begin = Alignment.topLeft,
    this.alignEnd = Alignment.bottomRight,
  });

  LinearGradient toLinearGradient() => LinearGradient(
        begin: begin,
        end: alignEnd,
        colors: [start, middle, end],
      );

  @override
  AppGradientTheme copyWith({
    Color? start,
    Color? middle,
    Color? end,
    Alignment? begin,
    Alignment? alignEnd,
  }) {
    return AppGradientTheme(
      start: start ?? this.start,
      middle: middle ?? this.middle,
      end: end ?? this.end,
      begin: begin ?? this.begin,
      alignEnd: alignEnd ?? this.alignEnd,
    );
  }

  @override
  AppGradientTheme lerp(ThemeExtension<AppGradientTheme>? other, double t) {
    if (other is! AppGradientTheme) return this;
    return AppGradientTheme(
      start: Color.lerp(start, other.start, t) ?? start,
      middle: Color.lerp(middle, other.middle, t) ?? middle,
      end: Color.lerp(end, other.end, t) ?? end,
      begin: Alignment.lerp(begin, other.begin, t) ?? begin,
      alignEnd: Alignment.lerp(alignEnd, other.alignEnd, t) ?? alignEnd,
    );
  }
}

