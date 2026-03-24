import 'package:flutter/material.dart';
import '../services/api_service.dart';

class IntervalsScreen extends StatefulWidget {
  const IntervalsScreen({super.key});

  @override
  State<IntervalsScreen> createState() => _IntervalsScreenState();
}

class _IntervalsScreenState extends State<IntervalsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  int _aliveInterval = 24;
  int _gracePeriod = 2;
  int _reminderBefore = 1;

  static const _aliveOptions = [
    {'hours': 6,   'label': 'Every 6 hours',  'pro': true},
    {'hours': 12,  'label': 'Every 12 hours', 'pro': true},
    {'hours': 24,  'label': 'Every 24 hours', 'pro': false},
    {'hours': 48,  'label': 'Every 2 days',   'pro': false},
    {'hours': 72,  'label': 'Every 3 days',   'pro': false},
    {'hours': 168, 'label': 'Every 7 days',   'pro': false},
  ];

  static const _graceOptions = [
    {'hours': 0,  'label': 'None'},
    {'hours': 1,  'label': '1 hour'},
    {'hours': 2,  'label': '2 hours'},
    {'hours': 4,  'label': '4 hours'},
    {'hours': 6,  'label': '6 hours'},
    {'hours': 12, 'label': '12 hours'},
    {'hours': 24, 'label': '24 hours'},
  ];

  static const _reminderOptions = [
    {'hours': 0, 'label': 'None'},
    {'hours': 1, 'label': '1 hour before'},
    {'hours': 2, 'label': '2 hours before'},
    {'hours': 4, 'label': '4 hours before'},
    {'hours': 6, 'label': '6 hours before'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.fetchSettings();
    if (mounted && data != null) {
      setState(() {
        _aliveInterval  = data['alive_interval_hours'] ?? 24;
        _gracePeriod    = data['grace_hours'] ?? 2;
        _reminderBefore = data['reminder_hours_before'] ?? 1;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _successMsg = null; _errorMsg = null; });
    final result = await ApiService.saveSettings(
      aliveIntervalHours: _aliveInterval,
      graceHours: _gracePeriod,
      reminderBeforeHours: _reminderBefore,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _successMsg = 'Settings saved successfully.');
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Failed to save settings.');
    }
  }

  void _showProModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 22),
            SizedBox(width: 8),
            Text('PRO Feature', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Shorter check-in intervals (6h, 12h) are available in the PRO plan.\n\nPRO plan coming soon!',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF9B7FE4))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Intervals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9B7FE4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  _buildSection(
                    icon: Icons.timer_outlined,
                    title: 'Check-in Interval',
                    description: 'How often you need to check in to confirm you\'re OK.',
                    child: _buildAliveDropdown(),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    icon: Icons.hourglass_bottom_outlined,
                    title: 'Grace Period',
                    description: 'Extra time after the deadline before guardians are alerted.',
                    child: _buildDropdown<int>(
                      value: _graceOptions.any((o) => o['hours'] == _gracePeriod) ? _gracePeriod : 2,
                      items: _graceOptions.map((o) => DropdownMenuItem<int>(
                        value: o['hours'] as int,
                        child: Text(o['label'] as String),
                      )).toList(),
                      onChanged: (v) => setState(() => _gracePeriod = v!),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    icon: Icons.notifications_outlined,
                    title: 'Reminder Before Expiration',
                    description: 'Send you a reminder notification before your check-in expires.',
                    child: _buildDropdown<int>(
                      value: _reminderOptions.any((o) => o['hours'] == _reminderBefore) ? _reminderBefore : 1,
                      items: _reminderOptions.map((o) => DropdownMenuItem<int>(
                        value: o['hours'] as int,
                        child: Text(o['label'] as String),
                      )).toList(),
                      onChanged: (v) => setState(() => _reminderBefore = v!),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMsg != null) ...[
                    _buildAlert(_errorMsg!, isError: true),
                    const SizedBox(height: 12),
                  ],
                  if (_successMsg != null) ...[
                    _buildAlert(_successMsg!, isError: false),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B7FE4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required String description, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF9B7FE4), size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAliveDropdown() {
    final value = _aliveOptions.any((o) => o['hours'] == _aliveInterval) ? _aliveInterval : 24;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (v) {
            final opt = _aliveOptions.firstWhere((o) => o['hours'] == v);
            if (opt['pro'] == true) { _showProModal(); return; }
            setState(() => _aliveInterval = v!);
          },
          items: _aliveOptions.map((o) {
            final isPro = o['pro'] == true;
            return DropdownMenuItem<int>(
              value: o['hours'] as int,
              child: Row(children: [
                Expanded(child: Text(o['label'] as String,
                    style: TextStyle(color: isPro ? Colors.white38 : Colors.white))),
                if (isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC857).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFFC857).withOpacity(0.4)),
                    ),
                    child: const Text('PRO', style: TextStyle(color: Color(0xFFFFC857), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _buildAlert(String msg, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isError ? Colors.red : Colors.green).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isError ? Colors.red : Colors.green).withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.redAccent : Colors.greenAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(color: isError ? Colors.redAccent : Colors.greenAccent, fontSize: 13))),
      ]),
    );
  }
}
