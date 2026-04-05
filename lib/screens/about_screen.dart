import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/pro_upgrade_modal.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isPro = false;
  bool _loading = true;
  bool _restoring = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isPro = await RevenueCatService.isPro();
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _isPro = isPro;
        _version = info.version;
        _loading = false;
      });
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final isPro = await RevenueCatService.restore();
    if (mounted) {
      setState(() { _isPro = isPro; _restoring = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isPro ? 'PRO restored successfully!' : 'No active PRO subscription found.'),
        backgroundColor: isPro ? Colors.green : Colors.orange,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('About', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  // App info card
                  Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Icon(Icons.favorite, color: Color(0xFF9B7FE4), size: 20),
                              const SizedBox(width: 8),
                              const Text('LastWish', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            ]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'v$_version',
                                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LastWish is a safety app that lets your trusted guardians know if something happens to you. '
                          'Check in regularly to confirm you\'re OK. If you miss a check-in, your guardians are automatically alerted.',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // PRO status card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isPro
                          ? const Color(0xFFFFC857).withOpacity(0.08)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isPro
                            ? const Color(0xFFFFC857).withOpacity(0.3)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Icon(
                                _isPro ? Icons.workspace_premium : Icons.lock_outline,
                                color: _isPro ? const Color(0xFFFFC857) : Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isPro ? 'PRO Plan' : 'Free Plan',
                                style: TextStyle(
                                  color: _isPro ? const Color(0xFFFFC857) : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isPro
                                    ? const Color(0xFFFFC857).withOpacity(0.15)
                                    : Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isPro ? 'ACTIVE' : 'FREE',
                                style: TextStyle(
                                  color: _isPro ? const Color(0xFFFFC857) : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isPro) ...[
                          _featureRow('Unlimited guardians', true),
                          _featureRow('Short check-in intervals (6h, 12h)', true),
                          _featureRow('Ring alert feature', true),
                          _featureRow('Unlimited protected persons', true),
                        ] else ...[
                          _featureRow('1 guardian', true),
                          _featureRow('Check-in intervals from 24h+', true),
                          _featureRow('Short intervals (6h, 12h)', false),
                          _featureRow('Ring alert feature', false),
                          _featureRow('Unlimited guardians', false),
                        ],
                        if (!_isPro) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC857),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final upgraded = await ProUpgradeModal.show(context, 'Upgrade to LastWish PRO');
                                if (upgraded == true) _load();
                              },
                              child: const Text('Upgrade to PRO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _restoring ? null : _restore,
                              child: _restoring
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
                                  : Text('Restore Purchase', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _featureRow(String text, bool available) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(
          available ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: available ? Colors.greenAccent : Colors.white24,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: available ? Colors.white70 : Colors.white24, fontSize: 13)),
      ]),
    );
  }
}
