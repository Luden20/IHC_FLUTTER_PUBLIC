import 'dart:async';
import 'package:appihv/dtos/evento_cabecera.dto.dart';
import 'package:appihv/dtos/evento_completo.dto.dart';
import 'package:appihv/dtos/users.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:pocketbase/pocketbase.dart';

import '../dtos/response.dto.dart';

class DataProvider {
  static final StreamController<String> _eventoActualizadoController =
      StreamController<String>.broadcast();

  static const Duration _cacheDuration = Duration(seconds: 30);
  static List<EventoCabeceraDTO>? _eventosCache;
  static DateTime? _eventosCacheAt;
  static Completer<List<EventoCabeceraDTO>>? _eventosRequest;
  static final Map<String, _CacheEntry<EventoCompletoDTO>> _eventoDetalleCache =
      <String, _CacheEntry<EventoCompletoDTO>>{};
  static final Map<String, Completer<EventoCompletoDTO>> _eventoRequests =
      <String, Completer<EventoCompletoDTO>>{};

  static Stream<String> get eventoActualizadoStream =>
      _eventoActualizadoController.stream;

  static void notifyEventoActualizado(String id) {
    _invalidateEventosCache();
    _invalidateEventoCache(id);
    if (_eventoActualizadoController.isClosed) return;
    _eventoActualizadoController.add(id);
  }

  static void clearCache() {
    _invalidateEventosCache();
    _eventoDetalleCache.clear();
  }

  static ActualUserDTO getUser() {
    return ActualUserDTO.fromRecordModel(PBService.actualUser!);
  }

  static Future<List<EventoCabeceraDTO>> getEventos({
    bool forceRefresh = false,
  }) async {
    final cachedEventos = _eventosCache;
    if (!forceRefresh &&
        cachedEventos != null &&
        _isCacheFresh(_eventosCacheAt)) {
      return cachedEventos;
    }

    final pending = _eventosRequest;
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<List<EventoCabeceraDTO>>();
    _eventosRequest = completer;

    try {
      final rawEventos = await PBService.client
          .collection('evento_cabecera')
          .getFullList(expand: 'Creador', sort: '+Fecha,+Activo');
      final eventos = List<EventoCabeceraDTO>.unmodifiable(
        rawEventos.map(EventoCabeceraDTO.fromRecordModel),
      );
      _eventosCache = eventos;
      _eventosCacheAt = DateTime.now();
      completer.complete(eventos);
      return eventos;
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      if (identical(_eventosRequest, completer)) {
        _eventosRequest = null;
      }
    }
  }

  static Future<EventoCompletoDTO> getEvento(
    String id, {
    bool forceRefresh = false,
  }) async {
    final cachedEvento = _eventoDetalleCache[id];
    if (!forceRefresh &&
        cachedEvento != null &&
        _isCacheFresh(cachedEvento.timestamp)) {
      return cachedEvento.value;
    }

    final pending = _eventoRequests[id];
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<EventoCompletoDTO>();
    _eventoRequests[id] = completer;

    try {
      final evento = await PBService.client
          .collection('evento_cabecera')
          .getOne(id, expand: 'Detalle,Creador,Asistentes');
      final dto = EventoCompletoDTO.fromRecordModel(evento);
      _eventoDetalleCache[id] = _CacheEntry<EventoCompletoDTO>(dto);
      completer.complete(dto);
      return dto;
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      final pendingRequest = _eventoRequests[id];
      if (identical(pendingRequest, completer)) {
        _eventoRequests.remove(id);
      }
    }
  }

  static Future<ResponseEventActionDto> sendPhotos(
    String id,
    List<MultipartFile> files,
  ) async {
    try {
      final cab = await PBService.client
          .collection('evento_cabecera')
          .getOne(id, expand: 'Detalle');

      final detExp = cab.get<RecordModel>('expand.Detalle', null);

      final det = await PBService.client
          .collection('evento_detalle')
          .getOne(detExp.id);
      final prev = List<String>.from(det.data['Fotos'] ?? const <String>[]);
      final _ = await PBService.client
          .collection('evento_detalle')
          .update(det.id, body: {'Fotos': prev}, files: files);
      notifyEventoActualizado(id);
      return ResponseEventActionDto(status: 'success', message: 'Fotos subidas.', id: '');
    } catch (e) {
      return ResponseEventActionDto(status: 'error', message: 'Error subiendo fotos', id: '');
    }
  }

  static Future<ResponseEventActionDto> joinEvent(String id) async {
    final res = await PBService.client.send(
      '/api/eventos/$id/invite',
      method: 'PUT',
    );
    return ResponseEventActionDto.fromJson(Map<String, dynamic>.from(res));
  }

  static Future<ResponseEventActionDto> setEventoActivado(String id, bool activado) async {
    try {
      if (kDebugMode) {
        debugPrint('Actualizando estado del evento: $id');
      }
      await PBService.client
          .collection('evento_cabecera')
          .update(id, body: {'Activo': activado});
      notifyEventoActualizado(id);
      final message = activado
          ? 'Evento activado correctamente.'
          : 'Evento desactivado.';
      return ResponseEventActionDto(status: 'success', message: message, id: '');
    } catch (e) {
      return ResponseEventActionDto(
        status: 'error',
        message: 'No se pudo actualizar el estado del evento', id: '',
      );
    }
  }
}

bool _isCacheFresh(DateTime? timestamp) {
  if (timestamp == null) return false;
  return DateTime.now().difference(timestamp) <= DataProvider._cacheDuration;
}

void _invalidateEventoCache(String id) {
  DataProvider._eventoDetalleCache.remove(id);
}

void _invalidateEventosCache() {
  DataProvider._eventosCache = null;
  DataProvider._eventosCacheAt = null;
}

class _CacheEntry<T> {
  _CacheEntry(this.value) : timestamp = DateTime.now();

  final T value;
  final DateTime timestamp;
}
