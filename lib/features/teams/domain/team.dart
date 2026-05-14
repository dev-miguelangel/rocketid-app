import '../../contacts/domain/contact.dart';
import 'sport.dart';

/// Géneros válidos para un equipo (coinciden con el enum del backend).
const List<String> kTeamGenders = ['male', 'female', 'mixed'];

String genderLabel(String? gender) {
  switch (gender) {
    case 'male':
      return 'Masculino';
    case 'female':
      return 'Femenino';
    case 'mixed':
      return 'Mixto';
    default:
      return 'Mixto';
  }
}

String roleLabel(String? role) {
  switch (role) {
    case 'owner':
      return 'Dueño';
    case 'captain':
      return 'Capitán';
    case 'member':
      return 'Miembro';
    default:
      return 'Miembro';
  }
}

class Team {
  const Team({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.gender,
    required this.sportId,
    this.ownerId,
    this.sport,
    this.ownerName,
    this.memberCount,
  });

  final String id;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final String gender;
  final int sportId;
  final String? ownerId;
  final Sport? sport;
  final String? ownerName;
  final int? memberCount;

  String get sportLabel => sport?.displayLabel ?? '';

  factory Team.fromJson(Map<String, dynamic> json) {
    final sportJson = json['sport'];
    final ownerJson = json['owner'];

    int parseInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

    int? count;
    for (final key in const [
      'memberCount',
      'membersCount',
      'memberCounts',
    ]) {
      final v = json[key];
      if (v is num) {
        count = v.toInt();
        break;
      }
    }
    final rawMembers = json['members'];
    if (count == null && rawMembers is List) count = rawMembers.length;

    return Team(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] is String &&
              (json['description'] as String).trim().isNotEmpty
          ? json['description'] as String
          : null,
      icon: (json['icon'] ?? 'groups').toString(),
      color: (json['color'] ?? '#34D399').toString(),
      gender: (json['gender'] ?? 'mixed').toString(),
      sportId: parseInt(json['sportId'] ?? json['sport_id']),
      ownerId: (json['ownerId'] ?? json['owner_id'] ?? ownerJson?['id'])
          ?.toString(),
      sport: sportJson is Map<String, dynamic> ? Sport.fromJson(sportJson) : null,
      ownerName: ownerJson is Map<String, dynamic>
          ? (ownerJson['name'] ?? ownerJson['email'])?.toString()
          : null,
      memberCount: count,
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.role,
    required this.status,
    required this.user,
  });

  final String id;
  final String teamId;
  final String userId;
  final String role;
  final String status;
  final Contact user;

  bool get isOwner => role == 'owner';
  bool get isCaptain => role == 'captain';

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final userId =
        (json['userId'] ?? json['user_id'] ?? userJson['id'] ?? '').toString();

    return TeamMember(
      id: (json['id'] ?? '').toString(),
      teamId: (json['teamId'] ?? json['team_id'] ?? '').toString(),
      userId: userId,
      role: (json['role'] ?? 'member').toString(),
      status: (json['status'] ?? 'active').toString(),
      user: Contact.fromJson(
        userJson.isNotEmpty ? userJson : {'id': userId},
      ),
    );
  }
}
