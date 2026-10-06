import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/colors.dart';
import 'api.dart';

class LocationService {
  static Timer? _timer;

  static bool get isTracking => _timer != null;

  static String? lastKnownLocationName;
  static final Map<String, String> _addressCache = {};

  // ── Reverse Geocoding: Convert lat/lng to Human-Readable Location Name ──
  static Future<String?> getAddressFromCoords(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    if (_addressCache.containsKey(key)) {
      return _addressCache[key];
    }

    // 1. Try BigDataCloud reverse geocoding
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final locality = (data['locality']?.toString() ?? '').trim();
        final city = (data['city']?.toString() ?? '').trim();
        final state = (data['principalSubdivision']?.toString() ?? '').trim();

        String name = '';
        if (locality.isNotEmpty && city.isNotEmpty && locality != city) {
          name = '$locality, $city';
        } else if (city.isNotEmpty && state.isNotEmpty && city != state) {
          name = '$city, $state';
        } else if (locality.isNotEmpty) {
          name = locality;
        } else if (city.isNotEmpty) {
          name = city;
        } else if (state.isNotEmpty) {
          name = state;
        }

        if (name.isNotEmpty) {
          _addressCache[key] = name;
          return name;
        }
      }
    } catch (_) {}

    // 2. Fallback to OpenStreetMap Nominatim
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=16&addressdetails=1',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'GTOConnectApp/1.0'})
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final place = addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['road'] ??
              addr['residential'];
          final city = addr['city'] ??
              addr['town'] ??
              addr['village'] ??
              addr['county'];
          final state = addr['state'];

          String name = '';
          if (place != null && city != null) {
            name = '$place, $city';
          } else if (city != null && state != null) {
            name = '$city, $state';
          } else if (place != null) {
            name = '$place';
          } else if (city != null) {
            name = '$city';
          }

          if (name.isNotEmpty) {
            _addressCache[key] = name;
            return name;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  // ── Resolve location text (coordinates or place name) to human-readable place ──
  static Future<String?> resolveLocationText(String? rawLoc) async {
    if (rawLoc == null) return null;
    final trimmed = rawLoc.trim();
    if (trimmed.isEmpty || trimmed == '—' || trimmed == '-') return null;

    // Check if rawLoc matches coordinates e.g. "28.5355, 77.3910"
    final coordMatch = RegExp(r'^(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)$').firstMatch(trimmed);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lng = double.tryParse(coordMatch.group(2)!);
      if (lat != null && lng != null) {
        final address = await getAddressFromCoords(lat, lng);
        if (address != null && address.isNotEmpty) return address;
      }
    }
    return trimmed;
  }

  static Future<String?> getCurrentLocationName() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
      final name = await getAddressFromCoords(pos.latitude, pos.longitude);
      if (name != null) lastKnownLocationName = name;
      return name;
    } catch (_) {
      return lastKnownLocationName;
    }
  }

  // ── Mandatory location validation and acquisition for check-in ────
  static Future<Position> ensureLocationForCheckIn() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Device Location (GPS) is turned off. Please turn on Location in your device settings to Check In.',
      );
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception(
          'Location access is mandatory for Check-In. Please grant location permission.',
        );
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable location permissions in app settings to Check In.',
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      getAddressFromCoords(pos.latitude, pos.longitude).then((name) {
        if (name != null) lastKnownLocationName = name;
      });
      return pos;
    } catch (e) {
      throw Exception(
        'Could not obtain GPS location: ${e.toString().replaceAll('Exception: ', '')}. Please ensure high accuracy GPS is enabled.',
      );
    }
  }

  // ── Get real GPS and send to backend ─────────────────
  static Future<void> startTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Device Location (GPS) is turned off. Please enable Location in settings.',
      );
    }

    // Check permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    // Every 2 minutes, starting now. The first fix is not awaited: indoors it
    // can take a long time and callers only need tracking to be switched on.
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _sendLocation();
    });
    unawaited(_sendLocation());
  }

  static Future<void> _sendLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 45),
      );
      // Tracking may have been stopped (check-out, sign-out) while waiting
      if (_timer == null) return;
      await updateLocation(pos.latitude, pos.longitude);
      getAddressFromCoords(pos.latitude, pos.longitude).then((name) {
        if (name != null) lastKnownLocationName = name;
      });
    } catch (e) {
      // silently fail
    }
  }

  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<Map<String, dynamic>?> getMyLocation() async {
    final data = await Api.get('/api/location/me');
    return data['location'];
  }

  static Future<void> updateLocation(double lat, double lng) async {
    await Api.post(
      '/api/location/update',
      body: {'latitude': lat, 'longitude': lng},
    );
  }

  static Future<List<dynamic>> getAllLive() async {
    final data = await Api.get('/api/location/all');
    return data['locations'] ?? [];
  }

  static Future<List<dynamic>> getHistory(String userId) async {
    final data = await Api.get('/api/location/history/$userId');
    return data['locations'] ?? [];
  }
}

// ── Reusable widget to display resolved human-readable location name ─────────
class LocationNameBadge extends StatefulWidget {
  final String? rawLocation;
  final double? latitude;
  final double? longitude;
  final TextStyle? style;
  final Color iconColor;
  final double iconSize;
  final bool showIcon;

  const LocationNameBadge({
    super.key,
    this.rawLocation,
    this.latitude,
    this.longitude,
    this.style,
    this.iconColor = kForest,
    this.iconSize = 11,
    this.showIcon = true,
  });

  @override
  State<LocationNameBadge> createState() => _LocationNameBadgeState();
}

class _LocationNameBadgeState extends State<LocationNameBadge> {
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(LocationNameBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawLocation != widget.rawLocation ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (widget.latitude != null && widget.longitude != null) {
      final res = await LocationService.getAddressFromCoords(
        widget.latitude!,
        widget.longitude!,
      );
      if (mounted && res != null) setState(() => _resolved = res);
      return;
    }

    if (widget.rawLocation != null) {
      final res = await LocationService.resolveLocationText(widget.rawLocation);
      if (mounted && res != null) setState(() => _resolved = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _resolved ?? widget.rawLocation ?? '—';
    if (text == '—' || text.isEmpty) return const SizedBox.shrink();

    final defaultStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: kDeepBlue,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(Icons.location_on_outlined, size: widget.iconSize, color: widget.iconColor),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            text,
            style: widget.style ?? defaultStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
