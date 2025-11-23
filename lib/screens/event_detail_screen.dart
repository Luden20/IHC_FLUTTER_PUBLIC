import 'package:appihv/service/data_provider.service.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:flutter/material.dart';
import '../components/event_specific/event_detail.dart';
import '../components/general/shinny_button.dart';
import '../dtos/evento_completo.dto.dart';
import 'package:pocketbase/pocketbase.dart';

// Using Theme.of(context).colorScheme

class EventDetailScreen extends StatefulWidget {
  final String id;

  const EventDetailScreen({super.key, required this.id});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<EventoCompletoDTO> _eventoFuture;
  late final UnsubscribeFunc  unsubscribeHeader;

  void _initRealtime()async{
    try{
      unsubscribeHeader=await PBService.client.collection('evento_cabecera').subscribe(widget.id, (e){
        if (!mounted) return;
        _refreshEvento();
      });
    }catch(err,st){
      debugPrint('Realtime subscribe header failed: $err');
      unsubscribeHeader=() async { };
    }

  }
  @override
  void initState() {
    super.initState();
    _eventoFuture = DataProvider.getEvento(widget.id);
    _initRealtime();
  }
  @override
  void dispose() {
    unsubscribeHeader();
    super.dispose();
  }

  Future<void> _refreshEvento() {
    final future = DataProvider.getEvento(widget.id, forceRefresh: true);
    setState(() {
      _eventoFuture = future;
    });
    return future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.tertiary),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          'Detalle del Evento',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvento,
        child: FutureBuilder<EventoCompletoDTO>(
          future: _eventoFuture,
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


            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  'No se encontró información del evento',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              );
            }

            final evento = snapshot.data!;

            return EventDetail(
                evento: evento,
                onRefresh:(){
                  _refreshEvento();
                }
            );
          },
        ),
      ),
    );
  }
}
