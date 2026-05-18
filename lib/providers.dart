import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/http/dio_client.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/application/session_controller.dart';
import 'features/auth/application/session_repository.dart';
import 'features/auth/application/session_state.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/google_sign_in_service.dart';
import 'features/auth/data/users_api.dart';
import 'features/contacts/data/contacts_api.dart';
import 'features/contacts/data/groups_api.dart';
import 'features/contacts/domain/contact.dart';
import 'features/contacts/domain/contact_group.dart';
import 'features/profile/data/profile_api.dart';
import 'features/teams/data/sports_api.dart';
import 'features/teams/data/teams_api.dart';
import 'features/teams/domain/sport.dart';
import 'features/teams/domain/team.dart';

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
    usersApi: ref.watch(usersApiProvider),
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

final usersApiProvider = Provider<UsersApi>((ref) {
  final dio = ref.watch(dioProvider);
  return UsersApi(dio);
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

final profileSearchProvider =
    FutureProvider.autoDispose.family<List<Contact>, String>((ref, query) {
  return ref.watch(contactsApiProvider).searchProfiles(query);
});

final groupsApiProvider = Provider<GroupsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return GroupsApi(dio);
});

final contactGroupsProvider =
    FutureProvider.autoDispose<List<ContactGroup>>((ref) {
  return ref.watch(groupsApiProvider).list();
});

final groupDetailProvider =
    FutureProvider.autoDispose.family<ContactGroup, String>((ref, id) {
  return ref.watch(groupsApiProvider).getById(id);
});

final teamsApiProvider = Provider<TeamsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return TeamsApi(dio);
});

final sportsApiProvider = Provider<SportsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SportsApi(dio);
});

final myTeamsProvider = FutureProvider.autoDispose<List<Team>>((ref) {
  return ref.watch(teamsApiProvider).list();
});

final teamSearchProvider =
    FutureProvider.autoDispose.family<List<Team>, String>((ref, query) {
  return ref.watch(teamsApiProvider).search(query);
});

final teamDetailProvider =
    FutureProvider.autoDispose.family<Team, String>((ref, id) {
  return ref.watch(teamsApiProvider).getById(id);
});

final teamMembersProvider =
    FutureProvider.autoDispose.family<List<TeamMember>, String>((ref, id) {
  return ref.watch(teamsApiProvider).members(id);
});

final teamRequestsProvider =
    FutureProvider.autoDispose.family<List<TeamMember>, String>((ref, id) {
  return ref.watch(teamsApiProvider).pendingRequests(id);
});

final sportsListProvider = FutureProvider.autoDispose<List<Sport>>((ref) {
  return ref.watch(sportsApiProvider).list();
});

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final logoutHandler = ref.watch(logoutHandlerProvider);
  return DioClient.createDio(
    secureStorage: secureStorage,
    onAuthFailure: logoutHandler.logout,
  );
});