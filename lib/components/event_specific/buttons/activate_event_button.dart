import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

import '../../../service/data_provider.service.dart';
import '../../general/shinny_button.dart';
import '../../general/toast.dart';

class ActivateEventButton extends StatefulWidget {
  const ActivateEventButton({
    super.key,
    required this.eventId,
    required this.isActive,
    this.onStatusChanged,
  });

  final String eventId;
  final bool isActive;
  final ValueChanged<bool>? onStatusChanged;

  @override
  State<ActivateEventButton> createState() => _ActivateEventButtonState();
}

class _ActivateEventButtonState extends State<ActivateEventButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);

    final target = !widget.isActive;
    final response = await DataProvider.setEventoActivado(widget.eventId, target);

    if (!mounted) return;

    final bool success = response.status.toLowerCase() == 'success';
    final String fallbackMessage = target?'Evento activado correctamente.':'Evento desactivado.';
    final messengerMessage =
        response.message.isNotEmpty ? response.message : fallbackMessage;

    // Usar helper seguro para SnackBars (evita errores en diálogos/contextos deconectados)
    personalizedToast(context, messengerMessage);

    if (success) {

      widget.onStatusChanged?.call(target);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isActive;
    final String text = isActive ? 'Ocultar' : 'Activar';
    final IconData icon =
        isActive ? Icons.visibility_off : Icons.power_settings_new;

    return ShinnyButton(
      onPressed: (){_toggle();},
      text: text,
      icons: icon,
      confetti: true,
      expand: false,
      width: 150,
      alternative: true,
      isLoading: _loading,

    );
  }
}
