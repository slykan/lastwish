import 'package:flutter/material.dart';
import 'package:lastwish/services/api_service.dart';

class GuardianAlerts extends StatelessWidget {
  final List<Map<String, dynamic>> protectedPeople;
  final void Function(Map<String, dynamic> person)? onRemind;

  const GuardianAlerts({
    super.key,
    required this.protectedPeople,
    this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final alertPeople = protectedPeople
        .where((p) => (p['status'] ?? '').toString().toUpperCase() == 'ALERT')
        .toList();

    if (alertPeople.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5E5E).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF5E5E).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFFD166), size: 20),
              const SizedBox(width: 8),
              Text(
                '${alertPeople.length} person${alertPeople.length > 1 ? 's' : ''} need attention',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alertPeople.map((person) => _AlertCard(
                person: person,
                onRemind: onRemind != null
                    ? () async {
                        final id = person['id'];
                        if (id == null) return false;
                        return await ApiService.remindProtected(id);
                      }
                    : null,
              )),
        ],
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  final Map<String, dynamic> person;
  final Future<bool> Function()? onRemind;

  const _AlertCard({required this.person, this.onRemind});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _showMedical = false;
  bool _remindLoading = false;
  bool? _remindResult;

  Future<void> _doRemind() async {
    if (_remindLoading) return;
    setState(() {
      _remindLoading = true;
      _remindResult = null;
    });
    final ok = await (widget.onRemind?.call() ?? Future.value(false));
    if (!mounted) return;
    setState(() {
      _remindLoading = false;
      _remindResult = ok;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _remindResult = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final hasMedical = [
      p['phone'], p['blood_type'], p['allergies'],
      p['medications'], p['emergency_note'],
    ].any((v) => v != null && v.toString().isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF5E5E).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5E5E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${p['name'] ?? 'Unknown'} - protector',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E5E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFF5E5E).withOpacity(0.4)),
                ),
                child: const Text(
                  'Alert',
                  style: TextStyle(
                    color: Color(0xFFFF5E5E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Remind button
              OutlinedButton(
                onPressed: _remindLoading ? null : _doRemind,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5E5E),
                  side: const BorderSide(color: Color(0xFFFF5E5E)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _remindLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF5E5E),
                        ),
                      )
                    : const Text('Remind', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              // Medical info button (samo ako ima medicinskih podataka)
              if (hasMedical)
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _showMedical = !_showMedical),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showMedical
                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                        : const Color(0xFF4CAF50).withOpacity(0.15),
                    foregroundColor: const Color(0xFF81C784),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child:
                      const Text('Medical info', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          // Medical info expanded
          if (_showMedical && hasMedical) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p['phone'] != null &&
                      p['phone'].toString().isNotEmpty)
                    _medRow('📞', 'Phone', p['phone']),
                  if (p['blood_type'] != null &&
                      p['blood_type'].toString().isNotEmpty)
                    _medRow('🩸', 'Blood type', p['blood_type']),
                  if (p['allergies'] != null &&
                      p['allergies'].toString().isNotEmpty)
                    _medRow('⚠️', 'Allergies', p['allergies']),
                  if (p['medications'] != null &&
                      p['medications'].toString().isNotEmpty)
                    _medRow('💊', 'Medications', p['medications']),
                  if (p['emergency_note'] != null &&
                      p['emergency_note'].toString().isNotEmpty)
                    _medRow('📋', 'Emergency note', p['emergency_note']),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _medRow(String emoji, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji ', style: const TextStyle(fontSize: 13)),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
