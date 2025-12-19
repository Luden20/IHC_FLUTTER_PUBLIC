import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PartyHatFallback extends StatelessWidget {
  const PartyHatFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      alignment: Alignment.center,
      child: Icon(
        Icons.celebration,
        size: 80,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
