class Sport {
  const Sport({
    required this.id,
    required this.name,
    required this.label,
    this.icon,
    this.color,
  });

  final int id;
  final String name;
  final String label;
  final String? icon;
  final String? color;

  String get displayLabel => label.trim().isNotEmpty ? label.trim() : name;

  factory Sport.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return Sport(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? json['name'] ?? '').toString(),
      icon: json['icon'] is String ? json['icon'] as String : null,
      color: json['color'] is String ? json['color'] as String : null,
    );
  }
}
