import 'dart:typed_data';

import 'package:appihv/service/data_provider.service.dart';
import 'package:appihv/service/permissions.service.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:pocketbase/pocketbase.dart';

class FullScreenPhotoGallery extends StatefulWidget {
  const FullScreenPhotoGallery({
    super.key,
    required this.fotos,
    required this.initialIndex,
    required this.eventId,
    required this.isActive,
    required this.creatorId,
    required this.eventTitle,
  });

  final List<String> fotos;
  final int initialIndex;
  final String eventId;
  final bool isActive;
  final String creatorId;
  final String eventTitle;

  @override
  State<FullScreenPhotoGallery> createState() => _FullScreenPhotoGalleryState();
}

class _FullScreenPhotoGalleryState extends State<FullScreenPhotoGallery> {
  late PageController _pageController;
  late List<String> _fotos;
  late int _index;
  bool _busy = false;

  bool get _isCreator => PBService.actualUser?.id == widget.creatorId;

  @override
  void initState() {
    super.initState();
    _fotos = List<String>.from(widget.fotos);
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrent() async {
    if (!widget.isActive) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El evento aún no inicia o está inactivo')),
      );
      return;
    }
    if (_busy || _fotos.isEmpty) return;
    setState(() => _busy = true);
    try {
      final granted = await checkAndRequestPermissions(skipIfExists: false);
      if (!granted || !mounted) return;
      final url = _fotos[_index];
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final fileName = _sanitizeFileName('${widget.eventTitle}_${_index + 1}.jpg');
      await SaverGallery.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        androidRelativePath: 'Pictures/appName/images',
        fileName: fileName,
        skipIfExists: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen guardada en galería')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la imagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteCurrent() async {
    if (!_isCreator || _busy || _fotos.isEmpty) return;
    final theme = Theme.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Deseas eliminar esta foto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final cabecera = await PBService.client
          .collection('evento_cabecera')
          .getOne(widget.eventId, expand: 'Detalle');
      final RecordModel? detalle =
          cabecera.get<RecordModel>('expand.Detalle', null);
      final String? detalleId = detalle?.id;
      if (detalleId == null) throw Exception('No se encontró el detalle del evento.');

      final remainingNames = _fotos
          .asMap()
          .entries
          .where((e) => e.key != _index)
          .map((e) => _extractFileName(e.value))
          .toList();

      await PBService.client
          .collection('evento_detalle')
          .update(detalleId, body: {'Fotos': remainingNames});

      DataProvider.notifyEventoActualizado(widget.eventId);

      if (!mounted) return;
      setState(() {
        _fotos.removeAt(_index);
        if (_index >= _fotos.length) _index = _fotos.length - 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto eliminada')),
      );

      if (_fotos.isEmpty && mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _extractFileName(String url) {
    final questionMarkIndex = url.indexOf('?');
    final sanitizedUrl =
        questionMarkIndex == -1 ? url : url.substring(0, questionMarkIndex);
    final segments = sanitizedUrl.split('/');
    return segments.isNotEmpty ? segments.last : sanitizedUrl;
  }

  String _sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _fotos.length;
    return Scaffold(
      backgroundColor: theme.colorScheme.scrim,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.scrim,
        leading: BackButton(color: theme.colorScheme.onPrimary),
        title: Text(
          total > 0 ? '${_index + 1} / $total' : 'Sin fotos',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Descargar',
            color: theme.colorScheme.onPrimary,
            onPressed: _busy ? null : _downloadCurrent,
            icon: const Icon(Icons.download),
          ),
          if (_isCreator)
            IconButton(
              tooltip: 'Eliminar',
              color: theme.colorScheme.onPrimary,
              onPressed: _busy ? null : _deleteCurrent,
              icon: const Icon(Icons.delete),
            ),
        ],
      ),
      body: PhotoViewGallery.builder(
        itemCount: total,
        pageController: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(_fotos[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
        backgroundDecoration: BoxDecoration(
          color: theme.colorScheme.scrim,
        ),
      ),
    );
  }
}
