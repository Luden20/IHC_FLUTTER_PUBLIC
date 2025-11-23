import 'package:appihv/service/pocketbase.service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'full_screen_photo.dart';

class EventPhotoGallery extends StatefulWidget {
  final List<String> Fotos;
  final String eventId;
  final bool isActive;
  final String creatorId;
  final String eventTitle;
  final ValueChanged<List<String>>? onSelectionChanged;
  const EventPhotoGallery({
    super.key,
    required this.Fotos,
    required this.eventId,
    required this.isActive,
    required this.creatorId,
    required this.eventTitle,
    this.onSelectionChanged,
  });

  @override
  State<EventPhotoGallery> createState() => _EventPhotoGalleryState();
}

class _EventPhotoGalleryState extends State<EventPhotoGallery> {
  final Set<int> seleccionados = {};

  @override
  void didUpdateWidget(covariant EventPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.Fotos, oldWidget.Fotos)) {
      seleccionados.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelectionChanged?.call(const []);
      });
    }

  }

  void _abrirPreview(int start) {
    if (!mounted || widget.Fotos.isEmpty) return;
    final fotos = List<String>.from(widget.Fotos);
    final targetIndex = start < 0
        ? 0
        : (start >= fotos.length ? fotos.length - 1 : start);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => FullScreenPhotoGallery(
          fotos: fotos,
          initialIndex: targetIndex,
          eventId: widget.eventId,
          isActive: widget.isActive,
          creatorId: widget.creatorId,
          eventTitle: widget.eventTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fotos = widget.Fotos;
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: fotos.length,
      itemBuilder: (ctx, i) {
        final url = fotos[i];
        final isSel = seleccionados.contains(i);
        final thumbUrl = PBService.fileThumbnailUrl(url, 300, 300);

        return GestureDetector(
          key: ValueKey(url),
          onTap: () => _abrirPreview(i),
          onLongPress: () {
            setState(() {
              isSel ? seleccionados.remove(i) : seleccionados.add(i);
            });
            final seleccionadas = seleccionados.map((idx) => fotos[idx]).toList();
            widget.onSelectionChanged?.call(seleccionadas);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: thumbUrl,
                  fit: BoxFit.cover,
                  cacheKey: '$url-300x300',
                  memCacheWidth: 300,
                  memCacheHeight: 300,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (_, __) => Container(
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: colorScheme.errorContainer.withOpacity(0.15),
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image, color: colorScheme.error),
                  ),
                ),
                if (isSel)
                  Container(color: colorScheme.scrim.withOpacity(0.26)),
                if (isSel)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.check_circle, color: colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
