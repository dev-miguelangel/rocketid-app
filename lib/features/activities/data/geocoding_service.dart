import 'package:dio/dio.dart';

/// Un resultado de geocodificación: una dirección con sus coordenadas.
class GeocodeResult {
  const GeocodeResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;
}

/// Geocodificación de direcciones con Nominatim (OpenStreetMap).
///
/// Usa un [Dio] propio (no el `dioProvider` de la app) porque apunta a un
/// servicio externo y no debe llevar el token ni el `baseUrl` del backend.
/// Nominatim exige un `User-Agent` identificable.
class GeocodingService {
  GeocodingService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://nominatim.openstreetmap.org',
                headers: const {'User-Agent': 'cl.rocketid.v1.app'},
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
              ),
            );

  final Dio _dio;

  /// Busca direcciones que coincidan con [query]. Devuelve lista vacía para
  /// consultas de menos de 3 caracteres.
  Future<List<GeocodeResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final response = await _dio.get<dynamic>(
      '/search',
      queryParameters: <String, dynamic>{
        'q': q,
        'format': 'jsonv2',
        'limit': 6,
        'accept-language': 'es',
        'countrycodes': 'cl',
      },
    );
    final data = response.data;
    if (data is! List) return const [];
    final results = <GeocodeResult>[];
    for (final item in data) {
      if (item is! Map) continue;
      final lat = double.tryParse('${item['lat']}');
      final lon = double.tryParse('${item['lon']}');
      if (lat == null || lon == null) continue;
      results.add(
        GeocodeResult(
          displayName: (item['display_name'] ?? '').toString(),
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return results;
  }
}
