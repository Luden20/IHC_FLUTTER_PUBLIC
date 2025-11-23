import 'dart:typed_data';
import 'package:appihv/components/general/toast.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:saver_gallery/saver_gallery.dart';

import '../../service/permissions.service.dart';
import '../general/shinny_button.dart';

class DownloadAllphotosButton extends StatefulWidget {
  const DownloadAllphotosButton({super.key, required this.urls,required this.evento, this.label = 'Descargar'});
  final List<String> urls;
  final String evento;
  final String label;

  @override
  State<DownloadAllphotosButton> createState() => _DownloadAllphotosButtonState();
}

class _DownloadAllphotosButtonState extends State<DownloadAllphotosButton> {
  bool _downloading = false;

  Future<void> _descargar() async {
    final granted = await checkAndRequestPermissions(skipIfExists: false);
    if (!granted || !mounted) return;

    setState(() => _downloading = true);

    try {
      for (var i = 0; i < widget.urls.length; i++) {
        final response = await Dio().get(
          widget.urls[i],
          options: Options(responseType: ResponseType.bytes),
        );
        final imageName = '${widget.evento}_$i.jpg';
        await SaverGallery.saveImage(
          Uint8List.fromList(response.data),
          quality: 60,
          androidRelativePath: 'Pictures/appName/images',
          fileName: imageName,
          skipIfExists: false,
        );
      }
      if (!mounted) return;
personalizedToast(context,'Imágenes guardadas correctamente');
    } catch (e) {
      debugPrint('Error al descargar: $e');
      if (!mounted) return;
      personalizedToast(context,"Error al guardar las imágenes");
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          ),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline, size: 18),
            SizedBox(width: 8),
            Text('Sin fotos'),
          ],
        ),
      );
    }

    return ShinnyButton(
      expand: false,
      alternative: true,

      onPressed: _downloading ? null : _descargar,
      text: widget.label,
      icons: Icons.download,
      isLoading: _downloading,
      width: 150,
    );
  }
}
