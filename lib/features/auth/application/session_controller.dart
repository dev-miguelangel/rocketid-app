import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_repository.dart';
import 'session_state.dart';

class SessionController extends StateNotifier<SessionState> {
  final SessionRepository _repository;

  SessionController(this._repository) : super(const SessionState.unknown());

  Future<void> bootstrap() async {
    final user = await _repository.bootstrap();
    if (user != null) {
      state = SessionState.authenticated(user);
    } else {
      state = const SessionState.unauthenticated();
    }
  }

  Future<void> loginWithGoogle() async {
    final user = await _repository.loginWithGoogle();
    state = SessionState.authenticated(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const SessionState.unauthenticated();
  }
}