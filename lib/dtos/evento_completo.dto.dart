import "package:appihv/dtos/users.dart";
import "package:pocketbase/pocketbase.dart";
import "../service/pocketbase.service.dart";
import "coordenadas.dto.dart";

class EventoCompletoDTO {
  final String id;
  final String Code;
  final String Titulo;
  final String Descripcion;
  final String Portada;
  final String PortadaCruda;
  final String Fecha;
  final String Lugar;
  final Coordenadas? GeoLugar;
  final UsersDTO Creador;
  final List<UsersDTO> Asisentes;
  final List<String> Fotos;
  final bool Activo;
  final String? DetalleId;

  EventoCompletoDTO({
    required this.id,
    required this.Code,
    required this.Asisentes,
    required this.Fotos,
    required this.Titulo,
    required this.Descripcion,
    required this.Portada,
    required this.PortadaCruda,
    required this.Fecha,
    required this.Lugar,
    required this.GeoLugar,
    required this.Creador,
    required this.Activo,
    this.DetalleId,
  });

  factory EventoCompletoDTO.fromRecordModel(RecordModel record) {
    final RecordModel? detalleRecord = record.get<RecordModel?>(
      'expand.Detalle',
    );
    final RecordModel creadorRecord = record.get<RecordModel>('expand.Creador');
    final asistentes =
        record.get<List<RecordModel>?>('expand.Asistentes') ??
        const <RecordModel>[];

    final fotos = detalleRecord == null
        ? <String>[]
        : record
              .getListValue("expand.Detalle.Fotos")
              .map((e) => PBService.fileUrl(detalleRecord, e))
              .toList();

    return EventoCompletoDTO(
      id: record.id,
      Code: record.getStringValue("Code"),
      Titulo: record.getStringValue("Titulo"),
      Descripcion: record.getStringValue("Descripcion"),
      Portada: PBService.fileUrl(record, record.getStringValue("Portada")),
      PortadaCruda: record.getStringValue("Portada"),
      Fecha: record.getStringValue("Fecha"),
      Lugar: record.getStringValue("Lugar"),
      GeoLugar: Coordenadas.tryParse(record.get('GeoLugar')),
      Creador: UsersDTO.fromRecordModel(creadorRecord),
      Asisentes: asistentes.map((e) => UsersDTO.fromRecordModel(e)).toList(),
      Fotos: fotos,
      Activo: record.getBoolValue("Activo"),
      DetalleId: detalleRecord?.id,
    );
  }
}
