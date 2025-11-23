import 'dart:math' as math;

import 'package:accordion/accordion.dart';
import 'package:appihv/components/general/shinny_button.dart';
import 'package:appihv/components/general/shinny_alt_button.dart';
import 'package:appihv/components/general/toast.dart';
import 'package:appihv/service/data_provider.service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../dtos/evento_completo.dto.dart';
import '../../service/pocketbase.service.dart';
import '../general/button_wrap.dart';
import '../general/cover_image.dart';
import 'info_card.dart' hide Avatar;
import 'photo_button.dart';
import 'qr_modal_button.dart';
import 'plain_code_modal_button.dart';
import '../general/section_title.dart';
import 'upload_photo_button.dart';
import 'activate_event_button.dart';
import '../general/avatar.dart';
import 'edit_event_button.dart';
import 'event_photo_gallery.dart';
import 'delete_photos.dart';
import 'download_photos.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
import 'package:pocketbase/pocketbase.dart';

class EventDetail extends StatefulWidget {
  final EventoCompletoDTO evento;
  const EventDetail({super.key, required this.evento, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  State<EventDetail> createState() => _EventDetailState();
}

class _EventDetailState extends State<EventDetail> {
  List<String> _seleccionadas = [];
  List<String> _fotos = [];
  late bool _isActive;
  late final UnsubscribeFunc  unsubscribeDetail;

  void _initRealtime() async{
    try{
      unsubscribeDetail = await PBService.client
          .collection('evento_detalle')
          .subscribe(widget.evento.DetalleId!, (e) {
        _refreshFotos();
      });
    }catch(err,st){
      debugPrint('Realtime subscribe detail failed: $err');
      unsubscribeDetail = () async {};
    }

  }
  @override
  void initState() {
    super.initState();
    _fotos = List<String>.from(widget.evento.Fotos);
    _isActive = widget.evento.Activo;
    _initRealtime();
  }
  @override
  void dispose() {
    unsubscribeDetail();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EventDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.id != widget.evento.id ||
        oldWidget.evento.Fotos != widget.evento.Fotos) {
      setState(() {
        _fotos = List<String>.from(widget.evento.Fotos);
        _seleccionadas = [];
        _isActive = widget.evento.Activo;
      });
    }
  }

  Future<void> _refreshFotos() async {
    try {
      final updated = await DataProvider.getEvento(
        widget.evento.id,
        forceRefresh: true,
      );

      setState(() {
        _fotos = List<String>.from(updated.Fotos);
        _seleccionadas = [];
        _isActive = updated.Activo;
      });
    } catch (_) {}
  }

  void _handleStatusChanged(bool isActive) {
    if (!mounted) return;
    setState(() {
      _isActive = isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final evento = widget.evento;
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(15),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final double infoWidth = maxWidth >= 720
                ? math.min(maxWidth / 2 - 24, 440)
                : maxWidth;
            final double coverWidth = maxWidth >= 720
                ? math.min(maxWidth / 2 - 24, 360)
                : maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: infoWidth,
                  child: InfoCard(
                    context,
                    theme,
                    evento,
                  ),
                ),
                SizedBox(
                  width: infoWidth,
                  child: CoverImage(evento.Portada, theme),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            color: theme.colorScheme.surfaceVariant, // Fondo
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: theme.colorScheme.outlineVariant, // Borde
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Creado por',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Spacer(),
                  Avatar(evento.Creador, theme, context, size: 48),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            color: theme.colorScheme.surfaceVariant, // Fondo
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: theme.colorScheme.outlineVariant, // Borde
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.group_outlined, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Asistentes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 70,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final asistente in evento.Asisentes)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Avatar(asistente, theme, context, size: 44),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children:    [
            if (PBService.actualUser?.id == evento.Creador.id)...[
              ActivateEventButton(
                eventId: evento.id,
                isActive: _isActive,
                onStatusChanged: (isActive) {
                  _handleStatusChanged(isActive);
                },
              ),
              EditEventButton(
                  eventId: evento.id,
                  onEventUpdated:(){
                    widget.onRefresh.call();
                  }
              )
            ]
            else...[

            ],
            ShinnyButton(
                icons: Icons.share,
                expand: false,
                width: 150,

                onPressed: (){
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Compartir"),
                        content: Text("Compartir evento"),
                        actions: [
                          QrModalButton(
                            qrText: 'appihv://compose/invite?code=${evento.Code}',
                          ),
                          const SizedBox(height: 16,),
                          PlainCodeModalButton(code: evento.Code),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cerrar"),
                          ),
                        ],
                      );
                    },
                  );
                }, text: "Compartir"),
            if(_isActive)...[
              Photobutton(idEvento: evento.id, onUploaded: _refreshFotos),
              UploadPhotoButton(idEvento: evento.id, onUploaded: _refreshFotos,),
              if (PBService.actualUser?.id == evento.Creador.id && _seleccionadas.isNotEmpty)
                DeletePhotosButton(
                  eventId: evento.id,
                  allUrls: _fotos,
                  selectedUrls: _seleccionadas,
                  label: 'Borrar (${_seleccionadas.length})',
                  onDeleted: _refreshFotos,
                ),
              DownloadAllphotosButton(
                urls: _seleccionadas.isNotEmpty ? _seleccionadas : _fotos,
                label: _seleccionadas.isNotEmpty ? '(${_seleccionadas.length})' : 'Todas',
                evento: evento.Titulo,
              ),
            ]
            else...[
              Container(
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
                  children:  [
                    Icon(Icons.info_outline, size: 18,color: Theme.of(context).colorScheme.error,),
                    SizedBox(width: 8),
                    Text(style: TextStyle(color: Theme.of(context).colorScheme.error),PBService.actualUser?.id == evento.Creador.id?
                    'El evento aun no inicia , activalo!!!'
                        :'El evento aun no inicia o esta inactivo'),
                  ],
                ),
              )
            ],
              if (PBService.actualUser?.id != evento.Creador.id)...[
                Container(
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
                    children:  [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Solo el creador puede borrar fotos'),
                    ],
                  ),
                ),
              ]
          ],
        ),
        const SizedBox(height: 10),
        EventPhotoGallery(
          Fotos: _fotos,
          eventId: evento.id,
          isActive: _isActive,
          creatorId: evento.Creador.id,
          eventTitle: evento.Titulo,
          onSelectionChanged: (urls) {
            setState(() {
              _seleccionadas = urls;
            });
          },
        ),

      ],
    );
  }
}
