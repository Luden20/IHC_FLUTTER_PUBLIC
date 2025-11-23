import 'package:flutter/material.dart';

import '../../screens/edit_event_screen.dart';
import '../general/shinny_button.dart';

class EditEventButton extends StatelessWidget {
  const EditEventButton({
    super.key,
    required this.eventId,
    this.onEventUpdated,
    this.label = 'Editar',
  });

  final String eventId;
  final VoidCallback? onEventUpdated;
  final String label;

  Future<void> _openEditor(BuildContext context) async {
    try {
      final updatedId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => EditEventScreen(eventId: eventId),
        ),
      );
      onEventUpdated?.call();

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el editor: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      onPressed: () => _openEditor(context),
      text: label,
      expand: false,
      width: 150,
      alternative: true,
      icons: Icons.edit,

    );
  }
}
