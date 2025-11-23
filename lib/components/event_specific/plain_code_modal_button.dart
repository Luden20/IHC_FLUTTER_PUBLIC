import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../general/shinny_button.dart';

class PlainCodeModalButton extends StatelessWidget {
  const PlainCodeModalButton({super.key, required this.code});

  final String code;

  Future<void> _shareCode(BuildContext context) async {
    final shareText = code.isEmpty
        ? 'No hay código disponible.'
        : 'Código de invitación: $code';
    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  void _openCodeModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final effectiveCode = code.isEmpty ? 'No hay código disponible.' : code;
        return AlertDialog(
          title: const Text('Código de invitación'),
          content: SelectableText(
            effectiveCode,
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => _shareCode(ctx),
              child: const Text('Compartir código'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      onPressed: () => _openCodeModal(context),
      text: 'Código',
      icons: Icons.share,
    );
  }
}
