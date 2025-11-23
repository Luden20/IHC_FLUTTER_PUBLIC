import 'package:flutter/material.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';

/// Contenedor con efecto glassmórfico y borde brillante.
/// Se adapta bien a distintos temas, con transparencia y blur.
class GlassBorderContainer extends StatelessWidget {
  final Widget prop;

  const GlassBorderContainer({super.key, required this.prop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: GlassMorphismContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: prop,
        ),
      ),
    );
  }
}
