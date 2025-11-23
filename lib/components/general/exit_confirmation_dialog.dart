import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

class ExitConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    String title = 'Salir de la aplicación',
    String message = '¿Deseas cerrar la aplicación?',
    String confirmLabel = 'Salir',
    String cancelLabel = 'Cancelar',
    DialogType dialogType = DialogType.warning,
    Color? confirmColor,
    Color? cancelColor,
  }) async {
    bool confirmed = false;

    await AwesomeDialog(
      context: context,
      dialogType: dialogType,
      title: title,
      desc: message,
      btnOkText: confirmLabel,
      btnCancelText: cancelLabel,
      btnOkColor: confirmColor,
      btnCancelColor: cancelColor,
      btnOkOnPress: () {
        confirmed = true;
      },
      btnCancelOnPress: () {},
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
      headerAnimationLoop: false,
    ).show();

    return confirmed;
  }
}
