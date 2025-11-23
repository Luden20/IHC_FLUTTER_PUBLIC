import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../../dtos/evento_completo.dto.dart';
import '../../service/date_time.util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';

Widget InfoCard(
    BuildContext context,
  ThemeData theme,
  EventoCompletoDTO evento) {
  final String lugar = evento.Lugar.trim().isEmpty
      ? 'Lugar sin definir'
      : evento.Lugar;
  String _formatFecha(String fechaStr) =>
      formatPocketbaseDateLocalShort(fechaStr);

  //return GlassMorphismCard(
  //tintColor: theme.colorScheme.primaryContainer,
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Card(
      margin: EdgeInsets.zero,

      // 🎨 Fondo del card
      color: theme.colorScheme.surfaceVariant,

      // 🟦 Borde del card
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant, // Borde
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evento.Titulo,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.tertiary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              evento.Descripcion,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              thickness: 1,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFecha(evento.Fecha),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lugar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lugar,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (evento.GeoLugar!.isValid()) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  MapsLauncher.launchCoordinates(
                    evento.GeoLugar!.Latitud,
                    evento.GeoLugar!.Longitud,
                    'Ubicación del evento ${evento.Titulo}',
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text('Ver en GoogleMaps'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

}
