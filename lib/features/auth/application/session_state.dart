import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/user.dart';

part 'session_state.freezed.dart';

@freezed
class SessionState with _$SessionState {
  const factory SessionState.unknown() = SessionUnknown;
  const factory SessionState.authenticated(User user) = SessionAuthenticated;
  const factory SessionState.unauthenticated() = SessionUnauthenticated;
}