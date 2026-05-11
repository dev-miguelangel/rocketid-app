import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    String? birthDate,
    String? gender,
    String? city,
    String? phone,
    String? alias,
    String? stringId,
    String? bloodType,
    List<String>? allergies,
    List<String>? conditions,
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
