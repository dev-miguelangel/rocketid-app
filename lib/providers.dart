import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/http/dio_client.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/application/session_controller.dart';
import 'features/auth/application/session_repository.dart';
import 'features/auth/application/session_state.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/google_sign_in_service.dart';
import 'features/contacts/data/contacts_api.dart';
import 'features/contacts/domain/contact.dart';
import 'features/profile/data/profile_api.dart';

class LogoutHandler {
  final Ref _ref;
  LogoutHandler(this._ref);

  Future<void> logout() async {
    final controller = _ref.read(sessionControllerProvider.notifier);
    await controller.logout();
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

final logoutHandlerProvider = Provider<LogoutHandler>((ref) {
  return LogoutHandler(ref);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    googleSignInService: ref.watch(googleSignInServiceProvider),
    authApi: ref.watch(authApiProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  return SessionController(repository);
});

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApi(dio);
});

final profileApiProvider = Provider<ProfileApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileApi(dio);
});

final contactsApiProvider = Provider<ContactsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ContactsApi(dio);
});

final myContactsProvider = FutureProvider.autoDispose<List<Contact>>((ref) {
  return ref.watch(contactsApiProvider).getContacts();
});

final contactSuggestionsProvider =
    FutureProvider.autoDispose<List<Contact>>((ref) {
  return ref.watch(contactsApiProvider).getSuggestions();
});

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final logoutHandler = ref.watch(logoutHandlerProvider);
  return DioClient.createDio(
    secureStorage: secureStorage,
    onAuthFailure: logoutHandler.logout,
  );
});