import 'package:appihv/service/data_provider.service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:flutter/foundation.dart';

import '../../general/shinny_button.dart';

class PhotoButton extends StatefulWidget {
  const PhotoButton({super.key, required this.idEvento, this.onUploaded});
  final String idEvento;
  final VoidCallback? onUploaded;

  @override
  State<PhotoButton> createState() => _PhotoButtonState();
}

class _PhotoButtonState extends State<PhotoButton> {
  bool _uploading = false;

  Future<void> _takePhoto() async {
    if (_uploading) return;

    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null) return;

    setState(() => _uploading = true);
    try {
      final files = [await MultipartFile.fromPath('Fotos', x.path)];
      final res = await DataProvider.sendPhotos(widget.idEvento, files);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      widget.onUploaded?.call();
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      expand: false,
      onPressed: _uploading ? null : _takePhoto,
      text: 'Tomar foto',
      width: 150,
      icons: Icons.camera_alt,
      isLoading: _uploading,
    );
  }
}
