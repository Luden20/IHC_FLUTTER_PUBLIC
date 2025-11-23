import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void personalizedToast(
  BuildContext context,
  String mensaje, {
  ScaffoldMessengerState? messengerState,
}) {
  // 1) Prefer supplied messengerState (e.g., from GlobalKey)
  // 2) Fallback to context's ScaffoldMessenger when safe
  ScaffoldMessengerState? messenger = messengerState;

  if (messenger == null) {
    try {
      messenger = ScaffoldMessenger.maybeOf(context);
    } catch (e) {
      debugPrint('⚠️ personalizedToast: context inválido');
      return;
    }
  }

  if (messenger == null || !messenger.mounted) {
    debugPrint('⚠️ personalizedToast: no hay ScaffoldMessenger activo');
    return;
  }

  // Construimos el SnackBar con el theme del messenger para evitar context inestable
  final theme = Theme.of(messenger.context);
  final bar = SnackBar(
    content: Text(
      mensaje,
      style: TextStyle(color: theme.colorScheme.onPrimary),
    ),
    backgroundColor: theme.colorScheme.primary,
  );

  // Evitar mostrar SnackBar durante build/dispose: posponer al próximo frame
  // Esto previene "Looking up a deactivated widget's ancestor is unsafe"
  void show() {
    if (!messenger!.mounted) return;
    messenger!.hideCurrentSnackBar();
    messenger!.showSnackBar(bar);
  }

  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
    // Estamos fuera de build: podemos mostrar inmediatamente
    show();
  } else {
    // Durante build/layout/paint: ejecutar al finalizar el frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) => show());
  }
}
