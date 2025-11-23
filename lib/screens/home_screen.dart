import 'dart:async';

import 'package:appihv/components/general/shinny_button.dart';
import 'package:flutter/material.dart';
import '../components/event_specific/event_detail.dart';
import '../components/event_specific/evento_item.dart';
import '../dtos/evento_cabecera.dto.dart';
import '../screen_enums.dart';
import '../service/data_provider.service.dart';
// Using Theme.of(context).colorScheme

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onEventSelected,
    required this.onIndexChange,
  });
  final void Function(screens value) onIndexChange;

  final ValueChanged<String> onEventSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<EventoCabeceraDTO>> _eventosFuture;
  StreamSubscription<String>? _eventoActualizadoSub;

  @override
  void initState() {
    super.initState();
    _eventosFuture = DataProvider.getEventos();
    _eventoActualizadoSub = DataProvider.eventoActualizadoStream.listen(
      (_) => _recargarEventos(forceRefresh: true),
    );
  }

  @override
  void dispose() {
    _eventoActualizadoSub?.cancel();
    super.dispose();
  }

  Future<void> _recargarEventos({bool forceRefresh = true}) async {
    final future = DataProvider.getEventos(forceRefresh: forceRefresh);
    setState(() {
      _eventosFuture = future;
    });
    await future;
  }

  void handleAuthChanged() {
    unawaited(_recargarEventos(forceRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Lista de eventos inscritos',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        //elevation: 5,
      ),
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _recargarEventos(forceRefresh: true),
        child: FutureBuilder(
          future: _eventosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
                ),
                child: ListView(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Sin conexión a internet",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Desliza hacia abajo para intentar de nuevo",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
                ),
                child: ListView(
                  children: [
                    ShinnyButton(
                      onPressed: () {
                        widget.onIndexChange(screens.join);
                      },
                      text: "Aun no tienes inscripciones, ¡únete!",
                      icons: Icons.add_circle_outlined,
                    ),
                    SizedBox(height: 20),
                    ShinnyButton(
                      alternative: true,
                      onPressed: () {
                        widget.onIndexChange(screens.create);
                      },
                      text: "O mejor ¡Crea tu la fiesta!",
                      icons: Icons.add_circle_outline,
                    ),
                  ],
                ),
              );
            }

            final eventos = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: eventos.length,
                      itemBuilder: (context, index) {
                        final evento = eventos[index];
                        return EventoItem(
                          evento: evento,
                          onOpenDetail: widget.onEventSelected,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 19),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

typedef HomeScreenState = _HomeScreenState;
