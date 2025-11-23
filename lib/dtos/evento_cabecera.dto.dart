import "package:appihv/dtos/users.dart";
import "package:pocketbase/pocketbase.dart";
import "../service/pocketbase.service.dart";
import "coordenadas.dto.dart";

class EventoCabeceraDTO {
  final String id;
  final String Code;
  final String Titulo;
  final String Descripcion;
  final String Portada;
  final String Fecha;
  final String Lugar;
  final Coordenadas? GeoLugar;
  final bool Activo;
  final UsersDTO Creador;
  EventoCabeceraDTO({
    required this.id,
    required this.Code,
    required this.Titulo,
    required this.Descripcion,
    required this.Portada,
    required this.Fecha,
    required this.Lugar,
    required this.GeoLugar,
    required this.Creador,
    required this.Activo,
  });
  factory EventoCabeceraDTO.fromRecordModel(RecordModel record) =>
      EventoCabeceraDTO(
        id: record.id,
        Code: record.getStringValue("Code"),
        Titulo: record.getStringValue("Titulo"),
        Descripcion: record.getStringValue("Descripcion"),
        Portada: PBService.fileUrl(record, record.getStringValue("Portada")),
        Fecha: record.getStringValue("Fecha"),
        Lugar: record.getStringValue("Lugar"),
        GeoLugar: Coordenadas.tryParse(record.get('GeoLugar')),
        Creador: UsersDTO.fromRecordModel(
          record.get<RecordModel>('expand.Creador', null),
        ),
        Activo: record.getBoolValue("Activo"),
      );
}
