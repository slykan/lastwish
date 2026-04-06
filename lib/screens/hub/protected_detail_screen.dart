import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class ProtectedDetailScreen extends StatefulWidget {
  final List<Map<String, dynamic>> protectedPeople;
  final Future<void> Function(Map<String, dynamic> person)? onRemind;
  final Future<void> Function(Map<String, dynamic> person)? onRemove;
  final Future<void> Function(Map<String, dynamic> person)? onLocate;

  const ProtectedDetailScreen({
    super.key,
    required this.protectedPeople,
    this.onRemind,
    this.onRemove,
    this.onLocate,
  });

  @override
  State<ProtectedDetailScreen> createState() => _ProtectedDetailScreenState();
}

class _ProtectedDetailScreenState extends State<ProtectedDetailScreen> {
  late List<Map<String, dynamic>> _people;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _people = List.from(widget.protectedPeople);
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final fresh = await ApiService.fetchProtectedPeople();
      setState(() {
        _people = List<Map<String, dynamic>>.from(fresh);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatRemaining(int seconds) {
    if (seconds <= 0) return 'Expired';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1030),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1030),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'People you protect',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white54, size: 22),
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: _people.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      color: Colors.white.withOpacity(0.2), size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'No protected persons',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 15),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.white,
              backgroundColor: const Color(0xFF2A1F50),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _people.length,
                itemBuilder: (context, index) {
                  return _PersonDetailCard(
                    person: _people[index],
                    formatRemaining: _formatRemaining,
                    onRemind: widget.onRemind != null
                        ? () => widget.onRemind!(_people[index])
                        : null,
                    onRemove: widget.onRemove != null
                        ? () async {
                            final confirmed = await _confirmRemove(context, _people[index]['name'] ?? '');
                            if (confirmed == true) {
                              await widget.onRemove!(_people[index]);
                              await _refresh();
                            }
                          }
                        : null,
                    onLocate: widget.onLocate != null
                        ? () => widget.onLocate!(_people[index])
                        : null,
                  );
                },
              ),
            ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove person',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Remove $name from your protection?',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFFF5E5E))),
          ),
        ],
      ),
    );
  }
}

class _PersonDetailCard extends StatefulWidget {
  final Map<String, dynamic> person;
  final String Function(int) formatRemaining;
  final VoidCallback? onRemind;
  final VoidCallback? onRemove;
  final VoidCallback? onLocate;

  const _PersonDetailCard({
    required this.person,
    required this.formatRemaining,
    this.onRemind,
    this.onRemove,
    this.onLocate,
  });

  @override
  State<_PersonDetailCard> createState() => _PersonDetailCardState();
}

class _PersonDetailCardState extends State<_PersonDetailCard> {
  bool _showMedical = false;
  bool _showHistory = false;
  List<dynamic> _history = [];
  bool _loadingHistory = false;
  int? _selectedHistoryIdx;
  final MapController _mapController = MapController();
  LatLng? _activeMapPoint;
  String _activeMapLabel = '';
  bool _mapReady = false;
  bool _remindLoading = false;
  bool? _remindResult;
  bool _locateLoading = false;
  bool? _locateResult;
  Timer? _ticker;
  late int _remainingSeconds;
  late int _maxSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = ((widget.person['remaining_seconds'] ?? 0) as num).toInt();
    final aliveH = (widget.person['alive_interval_hours'] ?? 24) as num;
    _maxSeconds = (aliveH * 3600).toInt();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapReady = true);
    });
  }

  @override
  void didUpdateWidget(_PersonDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLat = double.tryParse(widget.person['latitude']?.toString() ?? '');
    final newLng = double.tryParse(widget.person['longitude']?.toString() ?? '');
    final oldLat = double.tryParse(oldWidget.person['latitude']?.toString() ?? '');
    final oldLng = double.tryParse(oldWidget.person['longitude']?.toString() ?? '');
    if (newLat != null && newLng != null && (newLat != oldLat || newLng != oldLng)) {
      final newPoint = LatLng(newLat, newLng);
      setState(() {
        _activeMapPoint = newPoint;
        _activeMapLabel = widget.person['last_checkin_time']?.toString() ?? '';
      });
      _mapController.move(newPoint, 14);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    if (seconds <= 0) return 'Expired';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  Future<void> _doRemind() async {
    final id = widget.person['id'];
    if (id == null || _remindLoading) return;
    setState(() {
      _remindLoading = true;
      _remindResult = null;
    });
    final ok = await ApiService.remindProtected(id);
    if (!mounted) return;
    setState(() {
      _remindLoading = false;
      _remindResult = ok;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _remindResult = null);
    });
  }

  Future<void> _doLocate() async {
    if (_locateLoading || widget.onLocate == null) return;
    setState(() { _locateLoading = true; _locateResult = null; });
    try {
      widget.onLocate!();
      if (!mounted) return;
      setState(() { _locateLoading = false; _locateResult = true; });
      // Auto-refresh after 5s to pick up fresh location from protected device
      Future.delayed(const Duration(seconds: 5), () async {
        if (!mounted) return;
        await _refresh();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _locateLoading = false; _locateResult = false; });
    }
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _locateResult = null);
    });
  }

  String get _status => (widget.person['status'] ?? 'UNKNOWN').toString().toUpperCase();
  bool get _isAlert => _status == 'ALERT';
  bool get _isGrace => _status == 'GRACE';

  Color get _statusColor => _isAlert
      ? const Color(0xFFFF5E5E)
      : _isGrace
          ? const Color(0xFFFFC857)
          : const Color(0xFF5BFF6A);

  Future<void> _loadHistory() async {
    final id = widget.person['id'];
    if (id == null) return;
    setState(() => _loadingHistory = true);
    try {
      final data = await ApiService.fetchCheckinHistory(id);
      setState(() => _history = data);
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.person['name'] ?? 'Unknown';
    final email = widget.person['email'] ?? '';
    final lastCheckin = widget.person['last_checkin_time'] ?? 'Never';
    final method = widget.person['last_checkin_method'] ?? '';
    final remaining = (widget.person['remaining_seconds'] ?? 0) as num;
    final lat = double.tryParse(widget.person['latitude']?.toString() ?? '');
    final lng = double.tryParse(widget.person['longitude']?.toString() ?? '');
    final city = widget.person['city'] ?? '';
    final country = widget.person['country'] ?? '';
    final location = [city, country].where((e) => e.toString().isNotEmpty).join(', ');

    final phone = widget.person['phone']?.toString() ?? '';
    final bloodType = widget.person['blood_type']?.toString() ?? '';
    final allergies = widget.person['allergies']?.toString() ?? '';
    final medications = widget.person['medications']?.toString() ?? '';
    final emergencyNote = widget.person['emergency_note']?.toString() ?? '';
    final hasMedical = [phone, bloodType, allergies, medications, emergencyNote]
        .any((v) => v.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isAlert
              ? const Color(0xFFFF5E5E).withOpacity(0.35)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (hasMedical) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.medical_information_outlined,
                                size: 12,
                                color: const Color(0xFF5BFF6A).withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text(
                              'Medical information available',
                              style: TextStyle(
                                color: const Color(0xFF5BFF6A).withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCountdown(_remainingSeconds),
                      style: TextStyle(
                        color: _remainingSeconds <= 0
                            ? const Color(0xFFFF5E5E)
                            : _isGrace
                                ? const Color(0xFFFFC857)
                                : Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Progress bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _remainingSeconds <= 0 ? 'Overdue' : 'Remaining: ${_formatCountdown(_remainingSeconds)}',
                      style: TextStyle(
                        color: _remainingSeconds <= 0
                            ? const Color(0xFFFF5E5E)
                            : _isGrace
                                ? const Color(0xFFFFC857)
                                : Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _maxSeconds > 0 ? '${((_remainingSeconds / _maxSeconds).clamp(0.0, 1.0) * 100).toInt()}%' : '0%',
                      style: TextStyle(
                        color: Color.lerp(
                          const Color(0xFFFF5E5E),
                          const Color(0xFF5BFF6A),
                          _maxSeconds > 0 ? (_remainingSeconds / _maxSeconds).clamp(0.0, 1.0) : 0.0,
                        )!,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 7,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final progress = _maxSeconds > 0
                            ? (_remainingSeconds / _maxSeconds).clamp(0.0, 1.0)
                            : 0.0;
                        return Stack(
                          children: [
                            Container(
                              width: constraints.maxWidth,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF5E5E),
                                      Color(0xFFFFC857),
                                      Color(0xFF5BFF6A),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.close,
                      label: 'Remove',
                      color: const Color(0xFFFF5E5E),
                      onTap: widget.onRemove,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: _remindLoading ? Icons.hourglass_top : Icons.notifications_outlined,
                      label: 'Remind',
                      color: const Color(0xFF5BFF6A),
                      onTap: _remindLoading ? null : _doRemind,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.history,
                      label: 'History',
                      color: Colors.white60,
                      trailing: _showHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      onTap: () async {
                        setState(() => _showHistory = !_showHistory);
                        if (_showHistory && _history.isEmpty) {
                          await _loadHistory();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: _locateLoading ? Icons.hourglass_top : Icons.location_on_outlined,
                      label: 'Live locate',
                      color: const Color(0xFFFFC857),
                      onTap: _locateLoading ? null : _doLocate,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Locate feedback ──
          if (_locateResult != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: (_locateResult == true ? const Color(0xFF1E7E34) : const Color(0xFF7E1E1E)).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (_locateResult == true ? const Color(0xFF1E7E34) : const Color(0xFFFF5E5E)).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_locateResult == true ? Icons.check_circle_outline : Icons.error_outline,
                        size: 13, color: _locateResult == true ? const Color(0xFF5BFF6A) : const Color(0xFFFF5E5E)),
                    const SizedBox(width: 6),
                    Text(
                      _locateResult == true ? 'Location request sent' : 'Failed to send location request',
                      style: TextStyle(color: _locateResult == true ? const Color(0xFF5BFF6A) : const Color(0xFFFF5E5E), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // ── Remind feedback ──
          if (_remindResult != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: (_remindResult == true
                          ? const Color(0xFF1E7E34)
                          : const Color(0xFF7E1E1E))
                      .withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_remindResult == true
                            ? const Color(0xFF1E7E34)
                            : const Color(0xFFFF5E5E))
                        .withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _remindResult == true
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 13,
                      color: _remindResult == true
                          ? const Color(0xFF5BFF6A)
                          : const Color(0xFFFF5E5E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _remindResult == true
                          ? 'Reminder sent'
                          : 'Failed to send reminder',
                      style: TextStyle(
                        color: _remindResult == true
                            ? const Color(0xFF5BFF6A)
                            : const Color(0xFFFF5E5E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Map ──
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          Builder(builder: (context) {
            final mapPoint = _activeMapPoint ??
                (lat != null && lng != null ? LatLng(lat, lng) : null);
            final mapLabel = _activeMapLabel.isNotEmpty
                ? _activeMapLabel
                : lastCheckin;
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: mapPoint != null
                  ? SizedBox(
                      height: 200,
                      child: _mapReady
                          ? FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: mapPoint,
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.lastwish',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: mapPoint,
                                      width: 44,
                                      height: 56,
                                      child: Builder(builder: (context) {
                                        final initials = (widget.person['name'] ?? '')
                                            .toString()
                                            .trim()
                                            .split(' ')
                                            .where((w) => w.isNotEmpty)
                                            .take(2)
                                            .map((w) => w[0].toUpperCase())
                                            .join();
                                        const pinColor = Color(0xFF7B4FD4);
                                        return Column(
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
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.expand(),
                    )
                  : Container(
                      height: 100,
                      color: Colors.white.withOpacity(0.03),
                      child: Center(
                        child: Text(
                          'Nema lokacije',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13),
                        ),
                      ),
                    ),
            );
          }),

          // ── Last check-in info below map ──
          if (lat != null && lng != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 13, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 5),
                  Text(
                    'Last check-in: $lastCheckin',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  if (method.isNotEmpty) ...[
                    Text(
                      '  ·  ',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                    Text(
                      method,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 12),
                    ),
                  ],
                ],
              ),
            )
          else
            const SizedBox(height: 16),

          // ── Check-in history ──
          if (_showHistory) ...[
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _loadingHistory
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white38),
                      ),
                    )
                  : _history.isEmpty
                      ? Text(
                          'No history available',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in history',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 245,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _history.length > 30 ? 30 : _history.length,
                                itemBuilder: (ctx, idx) {
                                  final entry = _history[idx] as Map<String, dynamic>;
                                  final entryLat = double.tryParse(entry['lat']?.toString() ?? '');
                                  final entryLng = double.tryParse(entry['lng']?.toString() ?? '');
                                  final entryCity = entry['city']?.toString() ?? '';
                                  final entryCountry = entry['country']?.toString() ?? '';
                                  final location = [entryCity, entryCountry]
                                      .where((v) => v.isNotEmpty)
                                      .join(', ');
                                  final hasLocation = entryLat != null && entryLng != null;
                                  final isSelected = _selectedHistoryIdx == idx;
                                  final timeStr = entry['checked_in_at']?.toString() ?? '-';
                                  final displayLabel = location.isNotEmpty
                                      ? '$timeStr  ·  $location'
                                      : timeStr;

                                  return GestureDetector(
                                    onTap: hasLocation
                                        ? () {
                                            final point = LatLng(entryLat!, entryLng!);
                                            setState(() {
                                              _selectedHistoryIdx = idx;
                                              _activeMapPoint = point;
                                              _activeMapLabel = timeStr;
                                            });
                                            _mapController.move(point, 14);
                                          }
                                        : null,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 5),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF7B4FD4).withOpacity(0.18)
                                            : Colors.white.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF7B4FD4).withOpacity(0.5)
                                              : Colors.white.withOpacity(0.06),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 13,
                                            color: const Color(0xFF5BFF6A).withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              displayLabel,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                    isSelected ? 0.9 : 0.7),
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                entry['method']?.toString() ?? '',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.3),
                                                  fontSize: 10,
                                                ),
                                              ),
                                              if (hasLocation) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 11,
                                                  color: isSelected
                                                      ? const Color(0xFF7B4FD4)
                                                      : Colors.white.withOpacity(0.25),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],

          // ── Medical info (expandable) ──
          if (hasMedical) ...[
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            InkWell(
              onTap: () => setState(() => _showMedical = !_showMedical),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.medical_information_outlined,
                        size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      'Medical information',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65), fontSize: 13),
                    ),
                    const Spacer(),
                    Icon(
                      _showMedical
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_showMedical)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    if (phone.isNotEmpty)
                      _MedRow(icon: Icons.phone_outlined, label: 'Phone', value: phone, isPhone: true),
                    if (bloodType.isNotEmpty)
                      _MedRow(icon: Icons.bloodtype_outlined, label: 'Blood type', value: bloodType),
                    if (allergies.isNotEmpty)
                      _MedRow(icon: Icons.warning_amber_outlined, label: 'Allergies', value: allergies),
                    if (medications.isNotEmpty)
                      _MedRow(icon: Icons.medication_outlined, label: 'Medications', value: medications),
                    if (emergencyNote.isNotEmpty)
                      _MedRow(icon: Icons.note_outlined, label: 'Note', value: emergencyNote),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                Icon(trailing, size: 13, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPhone;

  const _MedRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPhone ? const Color(0xFF7B9FFF) : Colors.white70,
              fontSize: 12,
              decoration: isPhone ? TextDecoration.underline : TextDecoration.none,
              decorationColor: const Color(0xFF7B9FFF),
            ),
          ),
        ),
        if (isPhone)
          const Icon(Icons.call, size: 14, color: Color(0xFF7B9FFF)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: isPhone
          ? GestureDetector(
              onTap: () => launchUrl(Uri(scheme: 'tel', path: value)),
              child: content,
            )
          : content,
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
