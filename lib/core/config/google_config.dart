/// Single source of truth para identificadores de Google OAuth y configuración
/// asociada al backend de RocketID.
///
/// Cualquier referencia a estos IDs en código, docs o builds debe leer desde
/// aquí. No duplicar estos valores en otros archivos.
class GoogleConfig {
  const GoogleConfig._();

  /// Google Cloud Project ID.
  static const String projectId = 'rocketid-495422';

  /// OAuth 2.0 Client ID para clientes Android nativos.
  ///
  /// Origen: `docs/google_data/v1.json`.
  /// Vinculado al package `cl.rocketid.v1.app` y la huella SHA1 del keystore
  /// registrado en Google Cloud Console (ver `docs/google.md`).
  static const String androidClientId =
      '907664370232-eaja78td8icslear8bdivpsvf176e8dc.apps.googleusercontent.com';

  /// OAuth 2.0 Client ID de tipo Web.
  ///
  /// Se usa como `serverClientId` en el SDK `google_sign_in` para que el
  /// `idToken` emitido por Google sea aceptado por el backend.
  static const String webClientId =
      '907664370232-42tgp4q4emm4c85t7o7loug2at6er70i.apps.googleusercontent.com';

  /// `serverClientId` requerido por `google_sign_in` en Android para recibir
  /// un `idToken` validable por el backend.
  static const String serverClientId = webClientId;
}

/// Configuración del backend de autenticación de RocketID.
class AuthBackendConfig {
  const AuthBackendConfig._();

  /// Base URL del backend.
  ///
  /// TODO: migrar a HTTPS antes de producción. Mientras tanto, Android requiere
  /// una excepción de cleartext acotada a este host (ver `docs/google.md`).
  static const String baseUrl =
      'http://wlsc6ryuexi1391hw66vm9vz.166.0.112.2.sslip.io';

  /// Endpoint que intercambia el `idToken` de Google por tokens de la app.
  static const String googleTokenPath = '/auth/google/token';

  /// Endpoint para renovar el `accessToken` usando un `refreshToken` válido.
  /// Body esperado: `{ "refreshToken": "<jwt>" }`.
  /// Devuelve un nuevo par `accessToken` + `refreshToken` (rotación).
  static const String refreshTokenPath = '/auth/refresh';

  /// Endpoint que retorna el usuario autenticado a partir del `accessToken`
  /// enviado en el header `Authorization: Bearer <token>`.
  static const String mePath = '/auth/me';
}
