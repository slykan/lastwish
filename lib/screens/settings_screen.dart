import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  bool _notifyEmail = true;
  bool _notifyPush = true;

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
        _notifyEmail = (data['notify_email'] ?? true) == true ||
            (data['notify_email'] ?? 1) == 1;
        _notifyPush = (data['notify_push'] ?? true) == true ||
            (data['notify_push'] ?? 1) == 1;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _showBackgroundLocationDisclosure(BuildContext context) async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF9B7FE4).withOpacity(0.4), width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B7FE4).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_searching, color: Color(0xFF9B7FE4), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Background Location Access',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'LastWish collects your location data in the background.',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'This means the app can access your GPS location even when LastWish is closed or not in use.',
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B7FE4).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9B7FE4).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why we need this:',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Your guardians can request your real-time location even when the app is closed\n'
                      '• If you miss a check-in, your guardians can see your last known location\n'
                      '• Your location is only shared with guardians you have approved',
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5, height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: const Color(0xFF2ECC71).withOpacity(0.7), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your location data is never sold, never used for advertising, and never shared with third parties.',
                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Center(
                          child: Text('Not now', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B7FE4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Open Settings', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (agreed == true) {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _successMsg = null;
      _errorMsg = null;
    });

    // We need current interval settings too — fetch first so we don't overwrite them
    final current = await ApiService.fetchSettings();
    if (!mounted) return;

    final result = await ApiService.saveSettings(
      aliveIntervalHours: current?['alive_interval_hours'] ?? 24,
      graceHours: current?['grace_hours'] ?? 2,
      reminderBeforeHours: current?['reminder_hours_before'] ?? 1,
      notifyEmail: _notifyEmail ? 1 : 0,
      notifyPush: _notifyPush ? 1 : 0,
    );

    setState(() => _saving = false);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _successMsg = 'Notification preferences saved.');
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Failed to save.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9B7FE4)))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Choose how you want to receive notifications.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // ── Permissions info ──
                  _buildInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Background Location',
                    body: 'For Live Locate to work when the app is in the background, go to Settings → App → Location and select "Allow all the time".',
                    onTap: () => _showBackgroundLocationDisclosure(context),
                    buttonLabel: 'Open App Settings',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.battery_saver_outlined,
                    title: 'Battery Optimisation',
                    body: 'To ensure check-in reminders and location requests work reliably, disable battery optimisation for LastWish in your phone\'s settings.',
                    onTap: () => Geolocator.openLocationSettings(),
                    buttonLabel: 'Open Settings',
                  ),
                  const SizedBox(height: 20),

                  // ── Email ──
                  _buildToggleCard(
                    icon: Icons.email_outlined,
                    title: 'Email notifications',
                    subtitle:
                        'Receive alarm alerts, reminders and invite updates by email.',
                    value: _notifyEmail,
                    onChanged: (v) => setState(() => _notifyEmail = v),
                  ),

                  const SizedBox(height: 14),

                  // ── Push ──
                  _buildToggleCard(
                    icon: Icons.notifications_outlined,
                    title: 'Push notifications',
                    subtitle:
                        'Receive real-time push alerts on your device.',
                    value: _notifyPush,
                    onChanged: (v) => setState(() => _notifyPush = v),
                  ),

                  const SizedBox(height: 6),

                  // Warning when both off
                  if (!_notifyEmail && !_notifyPush)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFF6B35).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFF6B35), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You have disabled all notifications. You will not be alerted about alarms or invites.',
                              style: TextStyle(
                                  color: Color(0xFFFF6B35), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Save',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
    VoidCallback? onTap,
    String? buttonLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF9B7FE4), size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.5),
          ),
          if (onTap != null && buttonLabel != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B7FE4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF9B7FE4).withOpacity(0.4)),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    color: Color(0xFF9B7FE4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? const Color(0xFF9B7FE4).withOpacity(0.4)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF9B7FE4).withOpacity(0.18)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color:
                    value ? const Color(0xFF9B7FE4) : Colors.white38,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF9B7FE4),
            activeTrackColor: const Color(0xFF9B7FE4).withOpacity(0.35),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFE53935).withOpacity(0.12)
            : const Color(0xFF43A047).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? const Color(0xFFE53935).withOpacity(0.4)
              : const Color(0xFF43A047).withOpacity(0.4),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7),
          fontSize: 13.5,
        ),
      ),
    );
  }
}

