//Aca estan los usuarios inscritos
import "package:appihv/service/pocketbase.service.dart";
import "package:pocketbase/pocketbase.dart";

class UsersDTO{
  final String id;
  final String name;
  final String avatar;
  UsersDTO({required this.id,required this.name, required this.avatar} );
  factory UsersDTO.fromRecordModel(RecordModel  record) => UsersDTO(
    id: record.id,
    name: record.getStringValue("name"),
    avatar: _buildAvatarUrl(record),
  );
}
class ActualUserDTO{
  final String id;
  final String name;
  final String avatar;
  final String email;
  ActualUserDTO({required this.id,required this.name, required this.avatar, required this.email} );
  factory ActualUserDTO.fromRecordModel(RecordModel  record) => ActualUserDTO(
    id: record.id,
    name: record.getStringValue("name"),
    avatar: _buildAvatarUrl(record),
    email: record.getStringValue("email"),
  );
}

String _buildAvatarUrl(RecordModel record) {
  final String fileName = record.getStringValue('avatar');
  if (fileName.isEmpty) return '';
  return PBService.fileUrl(record, fileName);
}
