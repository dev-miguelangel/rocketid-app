import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    String? id,
    String? birthDate,
    // Edad calculada por el backend a partir de `birthDate`. `null` si no hay
    // fecha de nacimiento; entero con los años cumplidos en caso contrario.
    int? age,
    String? gender,
    String? city,
    String? phone,
    String? alias,
    String? stringId,
    String? bloodType,
    List<String>? allergies,
    String? conditions,
    List<String>? medications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? createdAt,
    String? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
