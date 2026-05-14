import 'contact.dart';

class ContactGroup {
  const ContactGroup({
    required this.id,
    required this.name,
    this.contacts = const [],
    this.contactCount,
  });

  final String id;
  final String name;
  final List<Contact> contacts;
  final int? contactCount;

  int get memberCount => contactCount ?? contacts.length;

  String get initial =>
      name.trim().isEmpty ? 'G' : name.trim()[0].toUpperCase();

  factory ContactGroup.fromJson(Map<String, dynamic> json) {
    final rawContacts = json['contacts'] ?? json['members'];
    final contacts = <Contact>[];
    if (rawContacts is List) {
      for (final e in rawContacts) {
        if (e is Map<String, dynamic>) {
          contacts.add(Contact.fromJson(e));
        }
      }
    }

    int? count;
    for (final key in const [
      'contactCount',
      'contactsCount',
      'memberCount',
      'membersCount',
      'count',
    ]) {
      final v = json[key];
      if (v is num) {
        count = v.toInt();
        break;
      }
    }
    if (count == null && rawContacts is List) count = rawContacts.length;

    return ContactGroup(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      contacts: contacts,
      contactCount: count,
    );
  }
}
