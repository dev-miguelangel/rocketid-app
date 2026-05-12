class Contact {
  const Contact({
    required this.id,
    this.userId,
    this.stringId,
    this.alias,
    this.name,
    this.email,
    this.avatar,
    this.city,
    this.phone,
  });

  final String id;
  final String? userId;
  final String? stringId;
  final String? alias;
  final String? name;
  final String? email;
  final String? avatar;
  final String? city;
  final String? phone;

  String get displayName {
    final candidates = [name, alias, email, stringId, id];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
    return 'Contacto';
  }

  String get initial {
    final source = displayName;
    return source.isEmpty ? 'R' : source[0].toUpperCase();
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : null;

    String? pick(String key) {
      final candidates = [json[key], profile?[key], user?[key]];
      for (final v in candidates) {
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    final id = pick('id') ?? pick('stringId') ?? pick('userId') ?? '';

    return Contact(
      id: id,
      userId: pick('userId') ?? user?['id'] as String?,
      stringId: pick('stringId'),
      alias: pick('alias'),
      name: pick('name'),
      email: pick('email'),
      avatar: pick('avatar'),
      city: pick('city'),
      phone: pick('phone'),
    );
  }
}
