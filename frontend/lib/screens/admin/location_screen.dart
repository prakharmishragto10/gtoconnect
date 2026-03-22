import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/colors.dart';
import '../../services/location_service.dart';
import 'dart:async';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _loading = true;
  List<dynamic> _locations = [];
  final MapController _mapController = MapController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadLocations(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await LocationService.getAllLive();
      setState(() {
        _locations = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _timeAgo(String? t) {
    if (t == null) return '—';
    final dt = DateTime.parse(t).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<Color> get _pinColors => [
    kDeepBlue,
    kForest,
    kTealGray,
    kBlueGray,
    const Color(0xFF7C3AED),
    const Color(0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepBlue));
    }

    // Calculate map center
    LatLng center = const LatLng(27.5, 79.0); // Default: North India
    if (_locations.isNotEmpty) {
      final lats = _locations
          .map((l) => (l['latitude'] as num).toDouble())
          .toList();
      final lngs = _locations
          .map((l) => (l['longitude'] as num).toDouble())
          .toList();
      center = LatLng(
        lats.reduce((a, b) => a + b) / lats.length,
        lngs.reduce((a, b) => a + b) / lngs.length,
      );
    }

    // Build markers
    final markers = _locations.asMap().entries.map((e) {
      final i = e.key;
      final loc = e.value;
      final user = loc['users'] as Map<String, dynamic>?;
      final name = user?['name'] ?? 'U';
      final lat = (loc['latitude'] as num).toDouble();
      final lng = (loc['longitude'] as num).toDouble();
      final color = _pinColors[i % _pinColors.length];

      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 70,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                name.split(' ').first,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kDeepBlue,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Location',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kDeepBlue,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _loading = true);
                  _loadLocations();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kInfoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, size: 14, color: kDeepBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kDeepBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: kForest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${_locations.length} employees sharing location',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: kTealGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Real Map
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _locations.length > 1 ? 6.5 : 12.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  // OpenStreetMap tiles
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gto.portal',
                  ),
                  // Employee markers
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          if (_locations.isNotEmpty) ...[
            Text(
              'MAP LEGEND',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: kTealGray,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _locations.asMap().entries.map((e) {
                final i = e.key;
                final loc = e.value;
                final user = loc['users'] as Map<String, dynamic>?;
                final name = user?['name'] ?? 'Unknown';
                final color = _pinColors[i % _pinColors.length];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kDeepBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Employee list
          Text(
            'EMPLOYEE POSITIONS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTealGray,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          if (_locations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No employees sharing location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: kTealGray,
                  ),
                ),
              ),
            )
          else
            ..._locations.asMap().entries.map((e) {
              final i = e.key;
              final loc = e.value;
              final user = loc['users'] as Map<String, dynamic>?;
              final name = user?['name'] ?? 'Unknown';
              final role = user?['designation'] ?? '—';
              final city = user?['location'] ?? '—';
              final lat = (loc['latitude'] as num).toDouble();
              final lng = (loc['longitude'] as num).toDouble();
              final time = _timeAgo(loc['recorded_at']);
              final color = _pinColors[i % _pinColors.length];

              return _LocationCard(
                name: name,
                role: role,
                city: city,
                lat: lat.toStringAsFixed(4),
                lng: lng.toStringAsFixed(4),
                lastSeen: time,
                color: color,
                onTap: () {
                  _mapController.move(LatLng(lat, lng), 13.0);
                },
              );
            }),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String name, role, city, lat, lng, lastSeen;
  final Color color;
  final VoidCallback onTap;

  const _LocationCard({
    required this.name,
    required this.role,
    required this.city,
    required this.lat,
    required this.lng,
    required this.lastSeen,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kDeepBlue,
                    ),
                  ),
                  Text(
                    role,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: kTealGray,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: kBlueGray,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        city,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kDeepBlue,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$lat°N  $lng°E',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: kTealGray,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kSuccessBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: kForest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: kForest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastSeen,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: kTealGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to focus',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: kBlueGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
