import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auth/domain/profile.dart';
import '../../auth/domain/user.dart';

part 'contact.freezed.dart';

@freezed
class Contact with _$Contact {
  const Contact._();

  const factory Contact({
    required User user,
    Profile? profile,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) {
    if (json['user'] is Map<String, dynamic>) {
      final userJson = json['user'] as Map<String, dynamic>;
      final profileJson = Map<String, dynamic>.from(json)..remove('user');
      return Contact(
        user: User.fromJson(userJson),
        profile: Profile.fromJson(profileJson),
      );
    }

    final userId = (json['userId'] ?? json['id'] ?? '').toString();
    final user = User(
      id: userId,
      email: (json['email'] ?? '').toString(),
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
    );

    const profileFieldKeys = [
      'city',
      'phone',
      'alias',
      'stringId',
      'birthDate',
      'age',
      'gender',
      'bloodType',
      'allergies',
      'conditions',
      'medications',
      'emergencyContactName',
      'emergencyContactPhone',
      'emergencyContactRelationship',
    ];
    final hasProfileFields = profileFieldKeys.any((k) => json[k] != null);
    final profile = hasProfileFields
        ? Profile.fromJson(<String, dynamic>{
            'id': null,
            for (final k in profileFieldKeys) k: json[k],
          })
        : null;

    return Contact(user: user, profile: profile);
  }

  String get id => user.id;
  String? get userId => user.id;
  String? get name => user.name;
  String? get email => user.email;
  String? get avatar => user.avatar;
  String? get city => profile?.city;
  String? get phone => profile?.phone;
  String? get alias => profile?.alias;
  String? get stringId => profile?.stringId;
  String? get birthDate => profile?.birthDate;
  int? get age => profile?.age;
  String? get gender => profile?.gender;
  String? get bloodType => profile?.bloodType;
  List<String>? get allergies => profile?.allergies;
  String? get conditions => profile?.conditions;
  List<String>? get medications => profile?.medications;
  String? get emergencyContactName => profile?.emergencyContactName;
  String? get emergencyContactPhone => profile?.emergencyContactPhone;
  String? get emergencyContactRelationship =>
      profile?.emergencyContactRelationship;

  String get displayName {
    final candidates = [
      user.name,
      profile?.alias,
      user.email,
      profile?.stringId,
      user.id,
    ];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
    return 'Contacto';
  }

  String get initial {
    final s = displayName;
    return s.isEmpty ? 'R' : s[0].toUpperCase();
  }
}
