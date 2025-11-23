import 'package:appihv/components/general/toast.dart';
import 'package:appihv/service/data_provider.service.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../general/shinny_button.dart';

class DeletePhotosButton extends StatefulWidget {
  const DeletePhotosButton({
    super.key,
    required this.eventId,
    required this.allUrls,
    required this.selectedUrls,
    this.label = 'Borrar',
    this.onDeleted,
  });

  final String eventId;
  final List<String> allUrls;
  final List<String> selectedUrls;
  final String label;
  final VoidCallback? onDeleted;

  @override
  State<DeletePhotosButton> createState() => _DeletePhotosButtonState();
}

class _DeletePhotosButtonState extends State<DeletePhotosButton> {
  bool _deleting = false;

  Future<void> _deleteSelected() async {
    if (_deleting || widget.selectedUrls.isEmpty) return;

    setState(() {
      _deleting = true;
    });

    try {
      final cabecera = await PBService.client
          .collection('evento_cabecera')
          .getOne(widget.eventId, expand: 'Detalle');

      final RecordModel? detalle =
          cabecera.get<RecordModel>('expand.Detalle', null);
      if (detalle == null) {
        throw Exception('No se encontró el detalle del evento.');
      }

      final remaining = widget.allUrls
          .where((url) => !widget.selectedUrls.contains(url))
          .map(_extractFileName)
          .toList();

      await PBService.client
          .collection('evento_detalle')
          .update(detalle.id, body: {'Fotos': remaining});

      DataProvider.notifyEventoActualizado(widget.eventId);

      if (!mounted) return;

personalizedToast(context, remaining.length == widget.allUrls.length
    ? 'No se eliminó ninguna foto.'
    : 'Fotos eliminadas correctamente.');

      widget.onDeleted?.call();
    } catch (e) {
      if (!mounted) return;
      personalizedToast(context,'Error al eliminar las fotos');
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedUrls.isNotEmpty;
    final semanticsLabel = hasSelection
        ? 'Eliminar ${widget.selectedUrls.length} foto${widget.selectedUrls.length == 1 ? '' : 's'} seleccionada${widget.selectedUrls.length == 1 ? '' : 's'}'
        : 'Botón eliminar fotos';

    return Semantics(
      button: true,
      enabled: hasSelection && !_deleting,
      label: semanticsLabel,
      child: ShinnyButton(
        expand: false,
        alternative: true,
        onPressed: (!hasSelection || _deleting) ? null : _deleteSelected,
        text: widget.label,
        icons: Icons.delete,
        isLoading: _deleting,
        width: 150,

      ),
    );
  }

  String _extractFileName(String url) {
    final questionMarkIndex = url.indexOf('?');
    final sanitizedUrl =
        questionMarkIndex == -1 ? url : url.substring(0, questionMarkIndex);
    final segments = sanitizedUrl.split('/');
    return segments.isNotEmpty ? segments.last : sanitizedUrl;
  }
}
