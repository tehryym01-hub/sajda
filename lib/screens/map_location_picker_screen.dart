import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final VoidCallback? onLocationConfirmed;
  const MapLocationPickerScreen({super.key, this.initialPosition, this.onLocationConfirmed});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _pickedPosition = const LatLng(21.4225, 39.8262); // Default: Kaaba
  String _address = 'Loading...';
  bool _loadingAddress = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _pickedPosition = widget.initialPosition!;
    } else {
      _getCurrentLocation();
    }
    _reverseGeocode(_pickedPosition);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _pickedPosition = latLng);
      _mapController.move(latLng, 15);
      _reverseGeocode(latLng);
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    if (_loadingAddress) return;
    setState(() => _loadingAddress = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}&accept-language=en',
      );
      final res = await http.get(url, headers: {'User-Agent': 'SajdaDataplus/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['display_name'] ?? 'Unknown location';
        if (!mounted) return;
        setState(() => _address = addr);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _address = 'Could not load address');
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _onMapMove() {
    final center = _mapController.camera.center;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _pickedPosition = center);
      _reverseGeocode(center);
    });
  }

  void _confirmLocation() {
    final state = context.read<AppState>();
    final cityName = _extractCity(_address);
    final countryName = _extractCountry(_address);
    state.setLocation(LocationModel(
      id: 'map_${DateTime.now().millisecondsSinceEpoch}',
      city: cityName,
      state: '',
      country: countryName,
      countryCode: '',
      latitude: _pickedPosition.latitude,
      longitude: _pickedPosition.longitude,
      timezone: '',
      source: 'MAP',
      isManual: false,
    ));
    if (widget.onLocationConfirmed != null) {
      widget.onLocationConfirmed!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  String _extractCity(String addr) {
    final parts = addr.split(',').map((e) => e.trim()).toList();
    for (final p in parts) {
      if (p.toLowerCase().contains('city') || p.toLowerCase().contains('town') || p.toLowerCase().contains('village')) continue;
      if (p.length > 2 && !p.contains(RegExp(r'^\d+$'))) return p;
    }
    return parts.isNotEmpty ? parts[0] : 'Unknown';
  }

  String _extractCountry(String addr) {
    final parts = addr.split(',').map((e) => e.trim()).toList();
    return parts.isNotEmpty ? parts.last : 'Unknown';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.t('Pick Location on Map', 'مقام منتخب کریں')),
        actions: [
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
            tooltip: state.t('My Location', 'میرا مقام'),
          ),
          IconButton(
            onPressed: _confirmLocation,
            icon: const Icon(Icons.check_rounded),
            tooltip: state.t('Confirm', 'تصدیق'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedPosition,
              initialZoom: 13,
              onMapEvent: (e) {
                if (e is MapEventMoveEnd) _onMapMove();
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sajda.dataplus',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          // Address panel
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 100,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.t('Selected Location', 'منتخب مقام'),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _loadingAddress
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_address, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          // Confirm button
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 24,
            child: SafeArea(
              top: false,
              child: FilledButton.icon(
                onPressed: _confirmLocation,
                icon: const Icon(Icons.check_rounded),
                label: Text(state.t('Confirm Location', 'مقام کی تصدیق کریں')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
