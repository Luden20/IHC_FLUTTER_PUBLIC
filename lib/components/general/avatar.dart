import 'package:appihv/service/pocketbase.service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../dtos/users.dart';

Widget Avatar(
  UsersDTO user,
  ThemeData theme,
  BuildContext context, {
  double size = 48,
}) {
  void showProfileDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) {
        final onSurface = theme.colorScheme.onSurface;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: Icon(Icons.close, color: onSurface),
                  ),
                ),
                Text(
                  'Perfil',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onSurface.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 75,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: user.avatar.isNotEmpty
                      ? NetworkImage(user.avatar)
                      : null,
                  child: user.avatar.isEmpty
                      ? Icon(
                          Icons.person,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 75,
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ImageProvider? _buildAvatarImage() {
    if (user.avatar.isEmpty) {
      return null;
    }
    final double referenceSize = size <= 0 ? 60 : size;
    final double pixelRatio =
        MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final double clamped = (referenceSize * pixelRatio).clamp(64.0, 256.0);
    final int targetSize = clamped.round();
    final String thumbUrl = PBService.fileThumbnailUrl(
      user.avatar,
      targetSize,
      targetSize,
    );
    return CachedNetworkImageProvider(thumbUrl);
  }

  final avatarImage = _buildAvatarImage();

  return GestureDetector(
    onTap: showProfileDialog,
    child: CircleAvatar(
      radius: 30,
      backgroundColor: theme.colorScheme.surfaceVariant,
      backgroundImage: avatarImage,
      child: avatarImage == null
          ? Icon(
              Icons.person,
              color: theme.colorScheme.onSurfaceVariant,
              size: 30,
            )
          : null,
    ),
  );
}
