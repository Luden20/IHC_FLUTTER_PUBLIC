import 'package:flutter/material.dart';
// Using Theme.of(context)
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

import '../../general/shinny_button.dart';

class QrModalButton extends StatelessWidget {
  final String qrText;

  const QrModalButton({super.key, required this.qrText});

  void _openQrModal(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'QR',
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (ctx, a1, a2) {
          const decoration = PrettyQrDecoration(
            // Ajusta tu estilo aquí (shape, image, quietZone, etc.)
            quietZone: PrettyQrQuietZone.standart,
          );

          return Center(
            child: Material(
              color: Theme.of(context).canvasColor,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 340,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tu código QR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.scrim,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        color: Theme.of(context).canvasColor, // <- fondo blanco visible desde theme
                        padding: const EdgeInsets.all(8),
                        child: PrettyQrView.data(
                          data: qrText.isEmpty ? ' ' : qrText,
                          decoration: decoration,
                          errorCorrectLevel: QrErrorCorrectLevel.M,
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final controller = ScreenshotController();
                              final exportWidget = Container(
                                color: Theme.of(context).canvasColor,
                                padding: const EdgeInsets.all(24),
                                child: PrettyQrView.data(
                                  data: qrText.isEmpty ? ' ' : qrText,
                                  decoration: decoration,
                                  errorCorrectLevel: QrErrorCorrectLevel.M,
                                ),
                              );
                              final bytes = await controller.captureFromWidget(
                                exportWidget,
                                pixelRatio: 4.0,
                              );
                              final file = XFile.fromData(
                                bytes,
                                name: 'codigo_qr.png',
                                mimeType: 'image/png',
                              );
                              await SharePlus.instance.share(
                                ShareParams(
                                  text: 'Escanea este código QR para acceder',
                                  files: [file],
                                ),
                              );
                            },
                            child: const Text('Compartir QR'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      onPressed: () => _openQrModal(context),
      text: 'QR',
      icons: Icons.qr_code,
    );
  }
}
