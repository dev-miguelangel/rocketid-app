import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';
import '../domain/pending_action.dart';

/// Cliente HTTP del inbox de acciones pendientes.
///
/// Cubre `GET /pending-actions`. El token JWT lo inyecta el interceptor de
/// `dioProvider`. Solo lectura: cada acción se resuelve con los flujos de
/// `ActivitiesApi` y `TeamsApi`.
class PendingActionsApi {
  PendingActionsApi(this._dio);

  final Dio _dio;

  String get _base => AuthBackendConfig.pendingActionsPath;

  /// `GET /pending-actions` — inbox del usuario autenticado.
  Future<PendingActionsInbox> inbox() async {
    final response = await _dio.get(_base);
    return _parseInbox(response.data);
  }

  static PendingActionsInbox _parseInbox(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] is Map<String, dynamic> ? data['data'] : data)
        : null;
    if (raw is! Map<String, dynamic>) {
      return const PendingActionsInbox(actions: [], total: 0);
    }
    return PendingActionsInbox.fromJson(raw);
  }
}
