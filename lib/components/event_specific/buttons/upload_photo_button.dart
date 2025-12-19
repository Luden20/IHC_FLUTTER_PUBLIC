import 'package:appihv/components/general/toast.dart';
import 'package:appihv/service/data_provider.service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' show MultipartFile;

import '../../general/shinny_button.dart';

class UploadPhotoButton extends StatefulWidget {
  const UploadPhotoButton({super.key, required this.idEvento, this.onUploaded});
  final String idEvento;
  final VoidCallback? onUploaded;

  @override
  State<UploadPhotoButton> createState() => _UploadPhotoButtonState();
}

class _UploadPhotoButtonState extends State<UploadPhotoButton> {
  bool _uploading = false;

  Future<void> _pickPhotos() async {
    if (_uploading) return;

    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final uploads = <MultipartFile>[];
      for (final file in files) {
        uploads.add(await MultipartFile.fromPath('Fotos', file.path));
      }
      final res = await DataProvider.sendPhotos(widget.idEvento, uploads);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      widget.onUploaded?.call();
    } catch (e) {
      debugPrint('Error al subir fotos: $e');
      if (!mounted) return;
      personalizedToast(context,'Error al subir las fotos');
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
      onPressed: _uploading ? null : _pickPhotos,
      text: 'Subir fotos',
      icons: Icons.photo_library,
      width: 150,
      isLoading: _uploading,
    );
  }
}
