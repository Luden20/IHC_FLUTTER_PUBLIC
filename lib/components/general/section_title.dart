import 'package:flutter/material.dart';

Widget SectionTitle(ThemeData theme, String title) {
  return Center(
    child: Text(
      title,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        shadows: [
          Shadow(
            color: theme.colorScheme.primary.withOpacity(0.5),
            blurRadius: 10,
          )
        ],
      ),
    ),
  );
}