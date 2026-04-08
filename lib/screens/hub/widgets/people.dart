import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../../services/api_service.dart';
import '../../../widgets/pro_upgrade_modal.dart';

class PeopleYouProtect extends StatelessWidget {
  final List<Map<String, dynamic>>? protectedPeople;
  final VoidCallback? onAddProtected;
  final VoidCallback? onLiveStatus;
  final void Function(Map<String, dynamic> person)? onPersonTap;

  const PeopleYouProtect({
    super.key,
    this.protectedPeople,
    this.onAddProtected,
    this.onLiveStatus,
    this.onPersonTap,
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
                    person: person,
                    onTap: onPersonTap != null ? () => onPersonTap!(person) : null,
                  ))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onLiveStatus,
                  icon: const Icon(Icons.remove_red_eye, size: 18),
                  label: const Text('Live status'),
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
        ],
      ),
    );
  }
}

class _PersonCard extends StatefulWidget {
  final Map<String, dynamic> person;
  final VoidCallback? onTap;

  const _PersonCard({
    required this.person,
    this.onTap,
  });

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  bool _showMedical = false;
  bool _locating = false;
  bool _ringing = false;
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
    debugPrint('PERSON CARD: name=${widget.person['name']} remaining=$_remainingSeconds max=$_maxSeconds aliveH=$aliveH progress=${_maxSeconds > 0 ? _remainingSeconds / _maxSeconds : 0} raw=${widget.person}');
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

  Future<void> _openLocation() async {
    setState(() => _locating = true);
    try {
      // Koristi zadnju poznatu lokaciju iz person objekta (check-in ili on_request)
      final lat = widget.person['latitude'] ?? widget.person['lat'];
      final lng = widget.person['longitude'] ?? widget.person['lng'];
      if (!mounted) return;
      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location data available.'), backgroundColor: Colors.orange),
        );
        return;
      }
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
          Row(
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
            ],
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
              if ((widget.person['phone']?.toString() ?? '').isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final phone = widget.person['phone'].toString();
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
              if ((widget.person['phone']?.toString() ?? '').isNotEmpty)
                const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _locating ? null : _openLocation,
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
        ), // Container
      ), // InkWell
    ); // Material
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
