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

  /// Base path para mutaciones de Profile.
  /// `PATCH /profiles/:id` actualiza campos editables del profile.
  static const String profilesPath = '/profiles';

  /// Endpoint para avanzar el onboarding del usuario autenticado.
  /// `PATCH /users/onboarding` body `{ "onboardingStep": <int> }`.
  static const String usersOnboardingPath = '/users/onboarding';

  /// Endpoints de contactos (red social).
  /// - `GET /profiles/contacts` lista los contactos del usuario.
  /// - `GET /profiles/contacts/suggestions` lista sugerencias / seguidores.
  /// - `POST /profiles/contacts/:stringId` agrega un contacto por stringId.
  static const String contactsPath = '/profiles/contacts';
  static const String contactSuggestionsPath = '/profiles/contacts/suggestions';

  /// Búsqueda de personas por alias, stringId o correo.
  /// `GET /profiles/search?q=<texto>`.
  static const String profileSearchPath = '/profiles/search';

  /// Grupos de contactos. El path es `/profiles/contact-groups` (no
  /// `/profiles/groups`) para no colisionar con `GET /profiles/:id`.
  /// - `POST /profiles/contact-groups` crea un grupo (nombre lowercase
  ///   alfanumérico, máx 30 chars). `409` si el nombre ya existe para el usuario.
  /// - `GET /profiles/contact-groups` lista los grupos del usuario.
  /// - `GET /profiles/contact-groups/:id` obtiene un grupo con sus contactos.
  /// - `PATCH /profiles/contact-groups/:id` renombra el grupo.
  /// - `DELETE /profiles/contact-groups/:id` elimina el grupo.
  /// - `POST /profiles/contact-groups/:id/contacts` agrega contactos al grupo.
  /// - `DELETE /profiles/contact-groups/:id/contacts` remueve contactos.
  static const String groupsPath = '/profiles/contact-groups';

  /// Equipos. `GET/POST /teams`, `GET/PATCH/DELETE /teams/:id`,
  /// `GET/POST /teams/:id/members`, `DELETE /teams/:id/members/:userId`,
  /// `PATCH /teams/:id/members/:userId/role`, `POST /teams/:id/join`,
  /// `POST /teams/:id/leave`, `GET /teams/:id/requests`,
  /// `POST /teams/:id/requests/:userId/accept|reject`.
  static const String teamsPath = '/teams';

  /// Catálogo de deportes: `GET /sports`.
  static const String sportsPath = '/sports';
}
