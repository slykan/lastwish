import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lastwish/services/api_service.dart';

class ActivityWidget extends StatefulWidget {
  final List<Map<String, dynamic>> protectedPeople;

  const ActivityWidget({super.key, required this.protectedPeople});

  @override
  State<ActivityWidget> createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
  bool _showHistory = false;
  List<dynamic> _history = [];
  bool _historyLoading = false;

  List<Map<String, dynamic>> get _recentActivities {
    final people = widget.protectedPeople;
    // Sortiraj po zadnjem checkin timestampu, najnoviji prvi
    final sorted = [...people];
    sorted.sort((a, b) {
      final at = a['last_checkin_timestamp'] ?? 0;
      final bt = b['last_checkin_timestamp'] ?? 0;
      return (bt as int).compareTo(at as int);
    });
    return sorted;
  }

  List<Marker> get _mapMarkers {
    final markers = <Marker>[];
    for (final p in widget.protectedPeople) {
      final lat = double.tryParse(p['latitude']?.toString() ?? '')
          ?? double.tryParse(p['lat']?.toString() ?? '');
      final lng = double.tryParse(p['longitude']?.toString() ?? '')
          ?? double.tryParse(p['lng']?.toString() ?? '');
      if (lat == null || lng == null) continue;
      final isAlert = (p['status'] ?? '').toString().toUpperCase() == 'ALERT';
      final isGrace = (p['status'] ?? '').toString().toUpperCase() == 'GRACE';

      final Color pinColor = isAlert
          ? const Color(0xFFFF5E5E)
          : isGrace
              ? const Color(0xFFFFC857)
              : const Color(0xFF9B7FE4);

      final String initials = ((p['name'] ?? '') as String)
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: pinColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: pinColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(12, 8),
                painter: _TrianglePainter(pinColor),
              ),
            ],
          ),
        ),
      );
    }
    return markers;
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final data = await ApiService.fetchActivityFeed();
    print("ACTIVITY FEED RAW: $data");
    print("ACTIVITY FEED LENGTH: ${data.length}");
    if (data.isNotEmpty) print("FIRST ITEM KEYS: ${(data.first as Map).keys.toList()}");
    setState(() {
      _history = data.take(50).toList();
      _historyLoading = false;
    });
  }

  void _toggleHistory() {
    if (!_showHistory && _history.isEmpty) {
      _loadHistory();
    }
    setState(() => _showHistory = !_showHistory);
  }

  @override
  Widget build(BuildContext context) {
    final markers = _mapMarkers;
    final activities = _recentActivities;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'Recent activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main content: list + map
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No activity yet',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity list
                ...activities.map((p) {
                  final isAlert =
                      (p['status'] ?? '').toString().toUpperCase() == 'ALERT';
                  final isGrace =
                      (p['status'] ?? '').toString().toUpperCase() == 'GRACE';
                  final time = p['last_checkin_time'] ?? '-';
                  final name = p['name'] ?? 'Unknown';

                  Color dotColor;
                  IconData dotIcon;
                  String label;

                  if (isAlert) {
                    dotColor = const Color(0xFFFF5E5E);
                    dotIcon = Icons.warning_amber_rounded;
                    label = '$name late';
                  } else if (isGrace) {
                    dotColor = const Color(0xFFFFC857);
                    dotIcon = Icons.warning_amber_rounded;
                    label = '$name - grace';
                  } else {
                    dotColor = const Color(0xFF5BFF6A);
                    dotIcon = Icons.check_circle_outline;
                    label = '$name checked in';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(dotIcon, size: 15, color: dotColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: dotColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (time != '-')
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Map full width
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 180,
                    child: markers.isEmpty
                        ? Container(
                            color: Colors.white.withOpacity(0.05),
                            child: Center(
                              child: Text(
                                'No location',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        : _SafeMap(
                            markers: markers,
                          ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 14),

          // Button: Activity timeline history
          GestureDetector(
            onTap: _toggleHistory,
            child: Row(
              children: [
                Text(
                  'Activity timeline history',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showHistory
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.white38,
                ),
              ],
            ),
          ),

          // History panel
          if (_showHistory) ...[
            const SizedBox(height: 12),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: _historyLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white38, strokeWidth: 2))
                  : _history.isEmpty
                      ? Center(
                          child: Text(
                            'No history',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withOpacity(0.06),
                            height: 1,
                          ),
                          itemBuilder: (context, i) {
                            final item = _history[i] as Map<String, dynamic>;
                            final isLate =
                                (item['type'] ?? '') == 'late';
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Icon(
                                    isLate
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    size: 14,
                                    color: isLate
                                        ? const Color(0xFFFF5E5E)
                                        : const Color(0xFF5BFF6A),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item['description'] ??
                                          '${item['person_name'] ?? ''} ${isLate ? 'late' : 'checked in'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item['time'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

class _SafeMap extends StatefulWidget {
  final List<Marker> markers;

  const _SafeMap({
    required this.markers,
  });

  @override
  State<_SafeMap> createState() => _SafeMapState();
}

class _SafeMapState extends State<_SafeMap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.expand();

    final MapOptions options;
    if (widget.markers.length == 1) {
      options = MapOptions(
        initialCenter: widget.markers.first.point,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      );
    } else {
      final bounds = LatLngBounds.fromPoints(
        widget.markers.map((m) => m.point).toList(),
      );
      options = MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
          maxZoom: 14,
        ),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      );
    }

    return FlutterMap(
      options: options,
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.lastwish.app',
        ),
        MarkerLayer(markers: widget.markers),
      ],
    );
  }
}
