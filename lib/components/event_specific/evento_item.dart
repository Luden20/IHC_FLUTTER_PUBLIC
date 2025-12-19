import 'package:appihv/components/event_specific/party_hat_fallback.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../dtos/evento_cabecera.dto.dart';
import '../../service/pocketbase.service.dart';
import '../../service/date_time.util.dart';
import '../general/avatar.dart';

class EventoItem extends StatefulWidget {
  final EventoCabeceraDTO evento;
  final ValueChanged<String> onOpenDetail;

  final double height;
  final double borderRadius;

  const EventoItem({
    super.key,
    required this.evento,
    required this.onOpenDetail,
    this.height = 325,
    this.borderRadius = 20,
  });

  @override
  State<EventoItem> createState() => _EventoItemState();
}

class _EventoItemState extends State<EventoItem> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evento = widget.evento;

    // Mostrar día y HH:mm en zona local (coincide con lo seleccionado)
    final fechaBonita = formatPocketbaseDateLocalShort(evento.Fecha);
    final Color dateColor = evento.Activo
        ? theme.colorScheme.onTertiary
        : theme.colorScheme.error;

    final bool hasImage = evento.Portada.isNotEmpty;

    return GestureDetector(
      onTap: hasImage ? () => widget.onOpenDetail(evento.id) : null,
      child: Card(
        color: Colors.transparent,
        elevation: 10,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                /// Fondo base (ligero tinte cuando hay imagen)
                Positioned.fill(
                  child: Container(
                    color: hasImage
                        ? theme.colorScheme.primary.withOpacity(0.001)
                        : Colors.transparent,
                  ),
                ),

                /// Imagen si existe; en error -> fallback con gorrito
                if (hasImage)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: PBService.fileThumbnailUrl(
                        evento.Portada,
                        800,
                        800,
                      ),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.celebration,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                /// Placeholder cuando NO hay imagen
                if (!hasImage)
                  const Positioned.fill(child: PartyHatFallback()),

                /// Gradiente para mejorar legibilidad del texto
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ),

                /// CONTENIDO PRINCIPAL (texto + avatar)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      /// Info del evento
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              evento.Titulo,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(blurRadius: 6, color: Colors.black54),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 14, color: dateColor),
                                const SizedBox(width: 4),
                                Text(
                                  fechaBonita,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: dateColor,
                                    fontWeight: FontWeight.w600,
                                    shadows: const [
                                      Shadow(
                                          blurRadius: 4, color: Colors.black54),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      /// Avatar del creador
                      Avatar(evento.Creador, theme, context, size: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

