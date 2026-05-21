import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/geocoding_service.dart';

/// Centro por defecto del mapa: Santiago de Chile.
const LatLng kDefaultMapCenter = LatLng(-33.4489, -70.6693);

/// Ubicación elegida en el selector: el punto y, si se geocodificó, la
/// dirección escrita.
class PickedLocation {
  const PickedLocation({required this.point, this.address});

  final LatLng point;
  final String? address;
}

/// Abre el selector de ubicación y devuelve el punto elegido (o `null`).
Future<PickedLocation?> pickActivityLocation(
  BuildContext context, {
  LatLng? initial,
}) {
  return showModalBottomSheet<PickedLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LocationPickerSheet(initial: initial),
  );
}

/// Hoja modal para fijar la ubicación: se escribe una dirección, se elige un
/// resultado y se ajusta el pin en un mapa de OpenStreetMap.
class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key, this.initial});

  final LatLng? initial;

  @override
  ConsumerState<LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final MapController _controller = MapController();
  final TextEditingController _search = TextEditingController();

  late LatLng _center;
  bool _locating = false;
  bool _searching = false;
  List<GeocodeResult> _results = const [];
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? kDefaultMapCenter;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _searchAddress() async {
    final query = _search.text.trim();
    if (query.length < 3) {
      _notify('Escribe una dirección más completa');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      final results =
          await ref.read(geocodingServiceProvider).search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
      if (results.isEmpty) _notify('No encontramos esa dirección');
    } on DioException {
      if (!mounted) return;
      setState(() => _searching = false);
      _notify('No pudimos buscar la dirección');
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
      _notify('No pudimos buscar la dirección');
    }
  }

  void _selectResult(GeocodeResult result) {
    final target = LatLng(result.latitude, result.longitude);
    setState(() {
      _center = target;
      _selectedAddress = result.displayName;
      _results = const [];
    });
    _controller.move(target, 16);
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    if (kIsWeb) {
      _notify('Disponible solo en la app móvil');
      return;
    }
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _notify('Activa la ubicación del dispositivo');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _notify('Permiso de ubicación denegado');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _center = target;
        _selectedAddress = null;
      });
      _controller.move(target, 16);
    } catch (_) {
      _notify('No pudimos obtener tu ubicación');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.88;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderChip,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Ubicación de la actividad',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchAddress(),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              cursorColor: AppColors.brandGreen,
              decoration: InputDecoration(
                hintText: 'Escribe una dirección',
                hintStyle: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  onPressed: _searching ? null : _searchAddress,
                  icon: _searching
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandGreen,
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward,
                          color: AppColors.brandGreen,
                          size: 20,
                        ),
                ),
                filled: true,
                fillColor: AppColors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderChip),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderChip),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.brandGreen),
                ),
              ),
            ),
          ),
          if (_results.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderChip),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _results.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.borderSubtle,
                ),
                itemBuilder: (context, i) {
                  final r = _results[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: AppColors.brandGreen,
                    ),
                    title: Text(
                      r.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () => _selectResult(r),
                  );
                },
              ),
            ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                    onPositionChanged: (camera, _) {
                      _center = camera.center;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'cl.rocketid.v1.app',
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.brandGreen,
                    size: 44,
                  ),
                ),
                if (!kIsWeb)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'use-location',
                      onPressed: _useMyLocation,
                      backgroundColor: AppColors.surfaceCard,
                      foregroundColor: AppColors.brandGreen,
                      child: _locating
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandGreen,
                              ),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ajusta el mapa para centrar el pin en el lugar exacto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    PickedLocation(
                      point: _center,
                      address: _selectedAddress,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Confirmar ubicación'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
