import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import '../../../widgets/pro_upgrade_modal.dart';

class PeopleYouProtect extends StatelessWidget {
  final List<Map<String, dynamic>>? protectedPeople;
  final VoidCallback? onAddProtected;
  final Future<void> Function(Map<String, dynamic> person)? onRemind;
  final Future<void> Function(Map<String, dynamic> person)? onRemove;
  final Future<void> Function(Map<String, dynamic> person)? onLocate;

  const PeopleYouProtect({
    super.key,
    this.protectedPeople,
    this.onAddProtected,
    this.onRemind,
    this.onRemove,
    this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    final people = protectedPeople ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.shield,
                size: 20,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              const Text(
                'People you protect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // People list
          if (people.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No protected people yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            )
          else
            Column(
                children: people
                  .map((person) => _PersonCard(
                    key: ValueKey(person['id'] ?? person['relationship_id']),
                    person: person,
                    onRemind: onRemind,
                    onRemove: onRemove,
                    onLocate: onLocate,
                  ))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddProtected,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add protected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatefulWidget {
  final Map<String, dynamic> person;
  final Future<void> Function(Map<String, dynamic> person)? onRemind;
  final Future<void> Function(Map<String, dynamic> person)? onRemove;
  final Future<void> Function(Map<String, dynamic> person)? onLocate;

  const _PersonCard({
    super.key,
    required this.person,
    this.onRemind,
    this.onRemove,
    this.onLocate,
  });

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  bool _expanded = false;
  bool _showMedical = false;
  bool _showHistory = false;
  bool _ringing = false;
  bool _locating = false;
  bool? _locateResult;
  bool _remindLoading = false;
  bool? _remindResult;
  List<dynamic> _history = [];
  bool _loadingHistory = false;
  int? _selectedHistoryIdx;
  final MapController _mapController = MapController();
  LatLng? _activeMapPoint;
  bool _mapReady = false;
  Timer? _ticker;
  late int _remainingSeconds;
  late int _maxSeconds;

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  void _initTimer() {
    _remainingSeconds = ((widget.person['remaining_seconds'] ?? 0) as num).toInt();
    final aliveH = (widget.person['alive_interval_hours'] ?? 24) as num;
    _maxSeconds = (aliveH * 3600).toInt();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
    });
  }

  @override
  void didUpdateWidget(_PersonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newRemaining = widget.person['remaining_seconds'] != null
        ? ((widget.person['remaining_seconds']) as num).toInt()
        : null;
    final oldRemaining = oldWidget.person['remaining_seconds'] != null
        ? ((oldWidget.person['remaining_seconds']) as num).toInt()
        : null;
    if (newRemaining != null && newRemaining != oldRemaining) {
      _ticker?.cancel();
      _initTimer();
    }

    final newLat = double.tryParse(widget.person['latitude']?.toString() ?? '');
    final newLng = double.tryParse(widget.person['longitude']?.toString() ?? '');
    final oldLat = double.tryParse(oldWidget.person['latitude']?.toString() ?? '');
    final oldLng = double.tryParse(oldWidget.person['longitude']?.toString() ?? '');
    if (newLat != null && newLng != null && (newLat != oldLat || newLng != oldLng)) {
      final newPoint = LatLng(newLat, newLng);
      setState(() {
        _activeMapPoint = newPoint;
      });
      if (_mapReady) _mapController.move(newPoint, 14);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '0s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  Future<void> _ring() async {
    final userId = widget.person['id'];
    if (userId == null) return;
    setState(() => _ringing = true);
    final result = await ApiService.ringProtected(userId as int);
    if (!mounted) return;
    setState(() => _ringing = false);

    if (result['upgrade_required'] == true) {
      ProUpgradeModal.show(context, 'Ring alarm is a PRO feature.');
      return;
    }

    final ok = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Ring signal sent!' : (result['message'] ?? 'Failed to send ring.')),
      backgroundColor: ok ? const Color(0xFF9B7FE4) : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _liveLocate() async {
    if (_locating || widget.onLocate == null) return;
    setState(() {
      _expanded = true;
      _locating = true;
      _locateResult = null;
    });
    if (!_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapReady = true);
      });
    }
    try {
      await widget.onLocate!(widget.person);
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locateResult = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locateResult = false;
      });
    }
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _locateResult = null);
    });
  }

  Future<void> _doRemind() async {
    if (widget.onRemind == null || _remindLoading) return;
    setState(() {
      _remindLoading = true;
      _remindResult = null;
    });
    try {
      await widget.onRemind!(widget.person);
      if (!mounted) return;
      setState(() {
        _remindLoading = false;
        _remindResult = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _remindLoading = false;
        _remindResult = false;
      });
    }
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _remindResult = null);
    });
  }

  Future<void> _doRemove() async {
    if (widget.onRemove == null) return;
    final name = widget.person['name'] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove person', style: TextStyle(color: Colors.white, fontSize: 16)),
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
            child: const Text('Remove', style: TextStyle(color: Color(0xFFFF5E5E))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onRemove!(widget.person);
    }
  }

  Future<void> _loadHistory() async {
    final id = widget.person['id'];
    if (id == null) return;
    setState(() => _loadingHistory = true);
    try {
      final data = await ApiService.fetchCheckinHistory(id);
      if (!mounted) return;
      setState(() => _history = data);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded && !_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapReady = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final name = person['name'] ?? 'Unknown';
    final lastCheckIn = person['last_checkin_time'] ?? 'Never';
    final status = person['status'] ?? 'Unknown';
    final phone = person['phone']?.toString() ?? '';

    final double progress = _maxSeconds > 0
        ? (_remainingSeconds / _maxSeconds).clamp(0.0, 1.0)
        : 0.0;
    final bool isOverdue = _remainingSeconds <= 0;
    final bloodType = person['blood_type']?.toString() ?? '';
    final allergies = person['allergies']?.toString() ?? '';
    final medications = person['medications']?.toString() ?? '';
    final emergencyNote = person['emergency_note']?.toString() ?? '';
    final hasMedical = [phone, bloodType, allergies, medications, emergencyNote]
        .any((v) => v.isNotEmpty);

    final isAlert = status.toUpperCase() == 'ALERT' || isOverdue;
    final isGrace = status.toUpperCase() == 'GRACE' && !isOverdue;

    final barColor = isAlert
        ? const Color(0xFFFF5E5E)
        : isGrace
            ? const Color(0xFFFFC857)
            : const Color(0xFF5BFF6A);

    // Progress boja: zelena (1.0) -> žuta (0.5) -> crvena (0.0)
    final progressColor = Color.lerp(
      const Color(0xFFFF5E5E),
      const Color(0xFF5BFF6A),
      progress.clamp(0.0, 1.0),
    )!;

    final lat = double.tryParse(person['latitude']?.toString() ?? '');
    final lng = double.tryParse(person['longitude']?.toString() ?? '');
    final mapPoint = _activeMapPoint ?? (lat != null && lng != null ? LatLng(lat, lng) : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert
            ? const Color(0xFFFF5E5E).withOpacity(0.08)
            : isGrace
                ? const Color(0xFFFFC857).withOpacity(0.08)
                : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFFF5E5E).withOpacity(0.3)
              : isGrace
                  ? const Color(0xFFFFC857).withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last check-in: $lastCheckIn',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: barColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverdue ? 'Overdue' : 'Remaining: ${_formatTime(_remainingSeconds)}',
                style: TextStyle(
                  color: isOverdue
                      ? const Color(0xFFFF5E5E)
                      : isGrace
                          ? const Color(0xFFFFC857)
                          : Colors.white.withOpacity(0.55),
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
                  return Stack(
                    children: [
                      // pozadina
                      Container(
                        width: constraints.maxWidth,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      // gradijent bar
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF5E5E), // crvena (lijevo)
                                Color(0xFFFFC857), // žuta (sredina)
                                Color(0xFF5BFF6A), // zelena (desno)
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

          // ── Action buttons ──
          const SizedBox(height: 10),
          Row(
            children: [
              // Ring button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ringing ? null : _ring,
                  icon: _ringing
                      ? const SizedBox(width: 13, height: 13,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFFFB347)))
                      : const Icon(Icons.notifications_active_outlined, size: 14),
                  label: const Text('Ring', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB347),
                    side: BorderSide(color: const Color(0xFFFFB347).withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (phone.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.phone_outlined, size: 14),
                    label: const Text('Call', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5BFF6A),
                      side: BorderSide(color: const Color(0xFF5BFF6A).withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                ),
              if (phone.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _locating ? null : _liveLocate,
                  icon: _locating
                      ? const SizedBox(width: 13, height: 13,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF9B7FE4)))
                      : const Icon(Icons.location_on_outlined, size: 14),
                  label: const Text('Locate', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9B7FE4),
                    side: BorderSide(color: const Color(0xFF9B7FE4).withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
            ],
          ),

          // ── Locate feedback ──
          if (_locateResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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

          // ── Expanded detail (in-place, no separate page) ──
          if (_expanded) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 12),

            // Remove / Remind
            Row(
              children: [
                _MiniActionButton(
                  icon: Icons.close,
                  label: 'Remove',
                  color: const Color(0xFFFF5E5E),
                  onTap: widget.onRemove != null ? _doRemove : null,
                ),
                const SizedBox(width: 8),
                _MiniActionButton(
                  icon: _remindLoading ? Icons.hourglass_top : Icons.notifications_outlined,
                  label: 'Remind',
                  color: const Color(0xFF5BFF6A),
                  onTap: widget.onRemind != null && !_remindLoading ? _doRemind : null,
                ),
              ],
            ),
            if (_remindResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: (_remindResult == true ? const Color(0xFF1E7E34) : const Color(0xFF7E1E1E)).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (_remindResult == true ? const Color(0xFF1E7E34) : const Color(0xFFFF5E5E)).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_remindResult == true ? Icons.check_circle_outline : Icons.error_outline,
                          size: 13, color: _remindResult == true ? const Color(0xFF5BFF6A) : const Color(0xFFFF5E5E)),
                      const SizedBox(width: 6),
                      Text(
                        _remindResult == true ? 'Reminder sent' : 'Failed to send reminder',
                        style: TextStyle(color: _remindResult == true ? const Color(0xFF5BFF6A) : const Color(0xFFFF5E5E), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // History toggle
            InkWell(
              onTap: () async {
                setState(() => _showHistory = !_showHistory);
                if (_showHistory && _history.isEmpty) {
                  await _loadHistory();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 13, color: Colors.white54),
                    const SizedBox(width: 6),
                    Text(
                      'Check-in history',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                    ),
                    const Spacer(),
                    Icon(
                      _showHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
            if (_showHistory) ...[
              const SizedBox(height: 8),
              _loadingHistory
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                        ),
                      ),
                    )
                  : _history.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No history available',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                          ),
                        )
                      : SizedBox(
                          height: 160,
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
                                        final point = LatLng(entryLat, entryLng);
                                        setState(() {
                                          _selectedHistoryIdx = idx;
                                          _activeMapPoint = point;
                                        });
                                        if (_mapReady) _mapController.move(point, 14);
                                      }
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                      Icon(Icons.check_circle_outline,
                                          size: 13, color: const Color(0xFF5BFF6A).withOpacity(0.7)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          displayLabel,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(isSelected ? 0.9 : 0.7),
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            entry['method']?.toString() ?? '',
                                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
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

            const SizedBox(height: 12),

            // Live map
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: mapPoint != null
                  ? SizedBox(
                      height: 180,
                      child: _mapReady
                          ? FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: mapPoint,
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.onclick.lastwish',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: mapPoint,
                                      width: 44,
                                      height: 56,
                                      child: Builder(builder: (context) {
                                        final initials = name
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
                          'No location yet',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        ),
                      ),
                    ),
            ),
          ],

          // ── Medical info (expandable) ──
          if (hasMedical) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _showMedical = !_showMedical),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medical_information_outlined,
                        size: 13, color: const Color(0xFF5BFF6A).withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Text(
                      'Medical information',
                      style: TextStyle(
                        color: const Color(0xFF5BFF6A).withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showMedical
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
            if (_showMedical) ...[
              const SizedBox(height: 10),
              if (phone.isNotEmpty)
                _MedRow(icon: Icons.phone_outlined, label: 'Phone', value: phone, isPhone: true),
              if (bloodType.isNotEmpty)
                _MedRow(icon: Icons.bloodtype_outlined, label: 'Blood type', value: bloodType),
              if (allergies.isNotEmpty)
                _MedRow(icon: Icons.warning_amber_outlined, label: 'Allergies', value: allergies),
              if (medications.isNotEmpty)
                _MedRow(icon: Icons.medication_outlined, label: 'Medications', value: medications),
              if (emergencyNote.isNotEmpty)
                _MedRow(icon: Icons.note_outlined, label: 'Emergency note', value: emergencyNote),
            ],
          ],
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.color,
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
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPhone ? const Color(0xFF7B9FFF) : Colors.white70,
              fontSize: 11,
              decoration: isPhone ? TextDecoration.underline : TextDecoration.none,
              decorationColor: const Color(0xFF7B9FFF),
            ),
          ),
        ),
        if (isPhone)
          const Icon(Icons.call, size: 13, color: Color(0xFF7B9FFF)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
