import 'dart:async';

import 'package:appihv/service/pocketbase.service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

import '../general/shinny_button.dart';

class UpdateAvatarButton extends StatefulWidget {
  const UpdateAvatarButton({super.key, this.onAvatarUpdated});

  final ValueChanged<String>? onAvatarUpdated;

  @override
  State<UpdateAvatarButton> createState() => _UpdateAvatarButtonState();
}

class _UpdateAvatarButtonState extends State<UpdateAvatarButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _loading = true);

    try {
      final String url = await _uploadAvatar(file);
      if (!mounted) return;
      widget.onAvatarUpdated?.call(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada.')),
      );
    } catch (error) {
      if (!mounted) return;
      final String message = error is ClientException
          ? (error.response['message']?.toString() ??
              'No se pudo actualizar el avatar.')
          : 'No se pudo actualizar el avatar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String> _uploadAvatar(XFile file) async {
    if (!PBService.isLoggedIn) {
      throw Exception('Debes iniciar sesión.');
    }

    final MultipartFile avatarFile =
        await MultipartFile.fromPath('avatar', file.path);

    final RecordModel updated =
        await PBService.client.collection('users').update(
      PBService.actualUser!.id,
      files: [avatarFile],
    );

    final String token = PBService.client.authStore.token;
    PBService.client.authStore.save(token, updated);

    final String fileName = updated.getStringValue('avatar');
    if (fileName.isEmpty) {
      throw Exception('No se recibió la imagen actualizada.');
    }
    return PBService.fileUrl(updated, fileName);
  }

  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      onPressed: _loading ? null : _handleTap,
      text: 'Actualizar foto',
      icons: Icons.camera_alt_outlined,
      isLoading: _loading,
      width: 220,
      height: 48,
    );
  }
}
