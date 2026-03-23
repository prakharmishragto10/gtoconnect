import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api.dart';

class LocationService {
  static Timer? _timer;

  // ── Get real GPS and send to backend ─────────────────
  static Future<void> startTracking() async {
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

    // Send immediately
    await _sendLocation();

    // Then every 2 minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _sendLocation();
    });
  }

  static Future<void> _sendLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await updateLocation(pos.latitude, pos.longitude);
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
