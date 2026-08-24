import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lastwish/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lastwish/screens/login_screen.dart';
import 'package:lastwish/screens/hub/widgets/status_hero.dart';
import 'package:lastwish/screens/hub/widgets/quick_stats.dart';
import 'package:lastwish/screens/hub/widgets/people.dart';
import 'package:lastwish/screens/hub/widgets/guardian_alerts.dart';
import 'package:lastwish/screens/hub/widgets/guardians.dart';
import 'package:lastwish/screens/hub/widgets/acivity.dart';
import 'package:lastwish/screens/hub/widgets/account_menu.dart';
import 'package:lastwish/screens/hub/widgets/invites.dart';
import 'package:lastwish/screens/hub/widgets/invite_dialog.dart';
import 'package:lastwish/screens/hub/widgets/sent_invites.dart';
import 'package:lastwish/screens/profile_screen.dart';
import 'package:lastwish/screens/settings_screen.dart';
import 'package:lastwish/screens/intervals_screen.dart';
import 'package:lastwish/screens/about_screen.dart';
import 'package:lastwish/services/revenue_cat_service.dart';
import 'package:lastwish/widgets/pro_upgrade_modal.dart';
import 'package:geolocator/geolocator.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with WidgetsBindingObserver {
  Timer? _ticker;

  int totalSeconds = 0;
  int remainingSeconds = 0;
  int gracePeriodSeconds = 0; // koliko sekundi je grace period

  bool isLoading = true;
  bool isCheckingIn = false;
  bool hasGuardian = false;
  bool flash = false;
  String userName = 'Protected user';
  bool _isPro = false;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? statusData;
  String? willText;
  List<Map<String, dynamic>> protectedPeople = [];

  List<Map<String, dynamic>> guardians = [];
  List<Map<String, dynamic>> invites = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestNotificationPermission();
    _listenForegroundNotifications();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowBackgroundLocationDisclosure();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _maybeShowBackgroundLocationDisclosure() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('bg_location_disclosure_shown') ?? false;
    if (shown || !mounted) return;

    await showDialog<void>(
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
                    width: 44, height: 44,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B7FE4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('I understand', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await prefs.setBool('bg_location_disclosure_shown', true);
  }

  void _listenForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final title = message.notification?.title ?? 'LastWish';
      final body = message.notification?.body ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              if (body.isNotEmpty)
                Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          backgroundColor: const Color(0xFF2A1F50),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Refresh data when notification arrives
      _loadData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await ApiService.getUser();
      final status = await ApiService.getStatus();
      final isPro = await RevenueCatService.isPro();
      final settings = await ApiService.fetchSettings();

      final guardiansApi = await ApiService.fetchGuardians();
      final invitesApi = await ApiService.fetchInvites();
      final protectedApi = await ApiService.fetchProtectedPeople();

      setState(() {
        userData = user;
        statusData = status;
        willText = (settings?['will_text'] ?? '').toString().trim().isEmpty ? null : settings?['will_text']?.toString().trim();
        _isPro = isPro || (user?['is_pro'] == true) || (user?['is_pro'] == 1);
        userName = user?['name'] ?? 'Protected user';
        hasGuardian = user?['has_guardian'] == true;
        totalSeconds = status?['total_seconds'] ?? 86400;
        remainingSeconds = status?['remaining_seconds'] ?? 0;
        // Grace period = zadnjih 15% ili API polje ako postoji
        gracePeriodSeconds =
            status?['grace_period_seconds'] ?? (totalSeconds * 0.15).toInt();
        guardians = List<Map<String, dynamic>>.from(guardiansApi);
        invites = List<Map<String, dynamic>>.from(invitesApi);
        protectedPeople = List<Map<String, dynamic>>.from(protectedApi);
        isLoading = false;
      });

      _startTicker();
    } catch (e) {
      setState(() {
        isLoading = false;
        hasGuardian = false;
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (remainingSeconds > 0) remainingSeconds--;
        flash = isGrace || isAlert ? !flash : false;
      });
    });
  }

  // Progress = koliko OSTAJE (1.0 = pun krug = safe, 0.0 = prazan = gotovo)
  double get progress {
    if (totalSeconds <= 0) return 0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  // Grace = ušao u zadnji period ali još nije 0
  bool get isGrace =>
      remainingSeconds > 0 && remainingSeconds <= gracePeriodSeconds;

  // Alert = 0 sekundi
  bool get isAlert => remainingSeconds <= 0;

  String get statusText {
    if (isAlert) return 'Alert';
    if (isGrace) return 'Grace';
    return 'Safe';
  }

  String formatTime(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final hours = s ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    final secs = s % 60;
    if (hours > 0) return '${hours}h ${minutes}m ${secs}s';
    if (minutes > 0) return '${minutes}m ${secs}s';
    return '${secs}s';
  }

  Future<bool> _showLocationDisclosure() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('location_disclosure_shown') ?? false;
    if (shown) return true;

    if (!mounted) return false;

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.location_on, color: Color(0xFF7C3AED), size: 24),
            SizedBox(width: 8),
            Text('Location Access', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'LastWish uses your location during check-in to share your last known position with your Guardian contacts if you miss a check-in.\n\n'
          'This helps keep you safe and ensures your Guardians can find you if needed.\n\n'
          'Location is only recorded when you check in and is never used for advertising.',
          style: TextStyle(color: Color(0xFFB0B0C8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Decline', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (agreed == true) {
      await prefs.setBool('location_disclosure_shown', true);
      return true;
    }
    return false;
  }

  Future<void> onCheckInPressed() async {
    if (isCheckingIn) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      final agreed = await _showLocationDisclosure();
      if (!agreed) return;
    }

    setState(() => isCheckingIn = true);

    try {
      final success = await ApiService.checkIn();
      if (!mounted) return;

      if (success) {
        final status = await ApiService.getStatus();
        setState(() {
          statusData = status;
          totalSeconds = status?['total_seconds'] ?? totalSeconds;
          remainingSeconds = status?['remaining_seconds'] ?? totalSeconds;
          gracePeriodSeconds =
              status?['grace_period_seconds'] ?? (totalSeconds * 0.15).toInt();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful ✓'),
            backgroundColor: Color(0xFF1E7E34),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in failed'),
            backgroundColor: Color(0xFFFF5E5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF5E5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isCheckingIn = false);
    }
  }

  void _showAccountMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final email = userData?['email'] ?? '-';
        final provider = userData?['provider'] ?? '-';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: AccountMenu(
            userName: userName,
            email: email,
            provider: provider,
            onProfile: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            onSettings: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            onIntervals: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IntervalsScreen()),
                );
              },
            onWill: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            onAbout: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            onLogout: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove("token");
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SpaceBackground(),
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: Colors.white,
                    backgroundColor: const Color(0xFF1e293b),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              // Username left
                              Text(
                                'Hi, $userName',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              // Center status
                              Expanded(
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAlert
                                          ? const Color(0xFFFF5E5E).withOpacity(0.15)
                                          : isGrace
                                              ? const Color(0xFFFFC857)
                                                  .withOpacity(0.12)
                                              : Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isAlert
                                            ? const Color(0xFFFF5E5E).withOpacity(0.4)
                                            : isGrace
                                                ? const Color(0xFFFFC857)
                                                    .withOpacity(0.3)
                                                : Colors.white.withOpacity(0.10),
                                      ),
                                    ),
                                    child: Text(
                                      statusText.toUpperCase(),
                                      style: TextStyle(
                                        color: isAlert
                                            ? const Color(0xFFFF5E5E)
                                            : isGrace
                                                ? const Color(0xFFFFC857)
                                                : Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        letterSpacing: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Menu right
                              IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white70),
                                onPressed: () => _showAccountMenu(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (hasGuardian)
                          Column(
                            children: [
                              StatusHero(
                                progress: progress,
                                statusText: statusText,
                                countdownText: formatTime(remainingSeconds),
                                onCheckInPressed: onCheckInPressed,
                                isAlert: isAlert,
                                isGrace: isGrace,
                                flash: flash,
                                isCheckingIn: isCheckingIn,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  isAlert
                                      ? 'Time is running out'
                                      : isGrace
                                          ? 'Grace period active'
                                          : hasGuardian
                                              ? 'Everything looks good'
                                              : 'Add a guardian to get started',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.68),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        else
                          _NoGuardianCard(),
                        const SizedBox(height: 16),
                        _WillCard(
                          willText: willText,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        QuickStats(
                          user: userData,
                          status: statusData,
                          protectedCount: protectedPeople.length,
                        ),
                        const SizedBox(height: 24),
                        GuardianAlerts(
                          protectedPeople: protectedPeople,
                          onRemind: (person) async {
                            final id = person['id'];
                            if (id == null) return;
                            final ok = await ApiService.remindProtected(id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok == true ? 'Reminder sent!' : 'Failed to send reminder.'),
                              backgroundColor: ok == true ? Colors.green : Colors.red,
                              duration: const Duration(seconds: 2),
                            ));
                          },
                        ),
                        const SizedBox(height: 12),
                        PeopleYouProtect(
                          protectedPeople: protectedPeople,
                          onRemind: (person) async {
                            final id = person['id'];
                            if (id == null) return;
                            final ok = await ApiService.remindProtected(id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok == true ? 'Reminder sent!' : 'Failed to send reminder.'),
                              backgroundColor: ok == true ? Colors.green : Colors.red,
                              duration: const Duration(seconds: 2),
                            ));
                          },
                          onRemove: (person) async {
                            final rid = person['relationship_id'];
                            if (rid == null) return;
                            final ok = await ApiService.removeProtected(rid);
                            if (!context.mounted) return;
                            if (ok) _loadData();
                          },
                          onLocate: (person) async {
                            if (!_isPro) {
                              ProUpgradeModal.show(context, 'Location request is a PRO feature. Upgrade to unlock.');
                              return;
                            }
                            final id = person['id'];
                            if (id == null) return;
                            await ApiService.requestLocation(id);
                            // Auto-refresh nakon 6s da pokupe novu lokaciju
                            Future.delayed(const Duration(seconds: 6), () {
                              if (mounted) _loadData();
                            });
                          },
                          onAddProtected: () async {
                            final sent = await showInviteDialog(context, role: 'protected');
                            if (!mounted) return;
                            if (sent == true) {
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Invitation sent!'),
                                backgroundColor: const Color(0xFF1E7E34),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 2),
                              ));
                            }
                          },
                        ),
                        GuardiansWidget(
                          guardians: guardians,
                          onInviteGuardian: () async {
                            final sent = await showInviteDialog(context, role: 'guardian');
                            if (!mounted) return;
                            if (sent == true) {
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Invitation sent!'),
                                backgroundColor: const Color(0xFF1E7E34),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 2),
                              ));
                            }
                          },
                          onRemoveGuardian: (g) async {
                            final id = g['relationship_id'];
                            if (id == null) return;
                            final ok = await ApiService.removeGuardian(id);
                            if (ok) _loadData();
                          },
                        ),
                        const SizedBox(height: 12),
                        const SentInvitesWidget(),
                        const SizedBox(height: 12),
                        InvitesWidget(
                          invites: invites,
                          onAccept: (invite) async {
                            final ok = await ApiService.acceptInvite(invite['id']);
                            if (!mounted) return;
                            if (ok) {
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Invitation accepted'),
                                backgroundColor: const Color(0xFF1E7E34),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Failed to accept invitation'),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ));
                            }
                          },
                          onDecline: (invite) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E2E),
                                title: const Text('Decline invitation', style: TextStyle(color: Colors.white)),
                                content: const Text('Are you sure you want to decline this invitation?',
                                    style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true || !mounted) return;
                            final ok = await ApiService.declineInvite(invite['id']);
                            if (!mounted) return;
                            if (ok) {
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Invitation declined'),
                                backgroundColor: Colors.grey.shade800,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ));
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        ActivityWidget(
                          protectedPeople: protectedPeople,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _WillCard extends StatefulWidget {
  final String? willText;
  final VoidCallback? onTap;

  const _WillCard({this.willText, this.onTap});

  @override
  State<_WillCard> createState() => _WillCardState();
}

class _WillCardState extends State<_WillCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasWill = widget.willText != null && widget.willText!.isNotEmpty;
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3D2270).withOpacity(0.55),
                  const Color(0xFF1A0E3A).withOpacity(0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF9B7FE4).withOpacity(_glow.value),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B7FE4).withOpacity(_glow.value * 0.4),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B7FE4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF9B7FE4).withOpacity(0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9B7FE4).withOpacity(_glow.value * 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_note_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    hasWill
                        ? widget.willText!.length > 80
                            ? '${widget.willText!.substring(0, 80)}…'
                            : widget.willText!
                        : 'Messages to loved ones in case something happens to me.',
                    style: TextStyle(
                      color: hasWill
                          ? Colors.white.withOpacity(0.88)
                          : Colors.white.withOpacity(0.75),
                      fontSize: 13.5,
                      height: 1.5,
                      fontStyle: hasWill ? FontStyle.normal : FontStyle.italic,
                      fontWeight: hasWill ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: const Color(0xFF9B7FE4).withOpacity(0.7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoGuardianCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined,
              color: Colors.white.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          Text(
            'No Guardian',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite a guardian to activate\nyour protection ring.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceBackground extends StatelessWidget {
  const _SpaceBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpacePainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              Color(0xFF2D2F68),
              Color(0xFF12051F),
              Color(0xFF020304),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

class _SpacePainter extends CustomPainter {
  final List<_Star> stars = List.generate(55, (index) {
    final rnd = math.Random(index * 17 + 9);
    return _Star(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      r: rnd.nextDouble() * 2.2 + 0.6,
      opacity: rnd.nextDouble() * 0.35 + 0.10,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Star {
  final double x, y, r, opacity;
  _Star(
      {required this.x,
      required this.y,
      required this.r,
      required this.opacity});
}