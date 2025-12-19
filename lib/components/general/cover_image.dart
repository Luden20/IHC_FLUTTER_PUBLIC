import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget CoverImage(String url, ThemeData theme) {
  final borderRadius = BorderRadius.circular(8);

  Widget placeholder() => ClipRRect(
    borderRadius: borderRadius,
    child: Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Icon(
        Icons.photo_camera_back_outlined,
        size: 56,
        color: theme.colorScheme.primary,
      ),
    ),
  );

  if (url.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: placeholder(),
    );
  }

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: url,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, _) => placeholder(),
          errorWidget: (context, _, __) => placeholder(),
        ),
      ),
    ),
  );
}
