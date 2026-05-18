import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';
import '../domain/contact.dart';

class ContactsApi {
  ContactsApi(this._dio);

  final Dio _dio;

  Future<List<Contact>> getContacts() async {
    final response = await _dio.get(AuthBackendConfig.contactsPath);
    return _parseList(response.data);
  }

  Future<List<Contact>> getSuggestions() async {
    final response = await _dio.get(AuthBackendConfig.contactSuggestionsPath);
    return _parseList(response.data);
  }

  Future<List<Contact>> searchProfiles(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final response = await _dio.get(
      AuthBackendConfig.profileSearchPath,
      queryParameters: <String, dynamic>{'q': q},
    );
    return _parseList(response.data);
  }

  Future<Contact?> addContact(String stringId) async {
    final id = stringId.trim();
    if (id.isEmpty) {
      throw ArgumentError('stringId vacío');
    }
    final response = await _dio.post('${AuthBackendConfig.contactsPath}/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return Contact.fromJson(data);
    }
    return null;
  }

  Future<void> removeContact(String stringId) async {
    final id = stringId.trim();
    if (id.isEmpty) {
      throw ArgumentError('stringId vacío');
    }
    await _dio.delete('${AuthBackendConfig.contactsPath}/$id');
  }

  static List<Contact> _parseList(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['contacts'] ?? data['items'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Contact.fromJson)
        .toList(growable: false);
  }
}
