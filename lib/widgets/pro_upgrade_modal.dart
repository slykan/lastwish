import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';

class ProUpgradeModal extends StatefulWidget {
  final String reason;

  const ProUpgradeModal({super.key, required this.reason});

  static Future<bool> show(BuildContext context, String reason) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProUpgradeModal(reason: reason),
    );
    return result == true;
  }

  @override
  State<ProUpgradeModal> createState() => _ProUpgradeModalState();
}

class _ProUpgradeModalState extends State<ProUpgradeModal> {
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await RevenueCatService.getPackages();
    if (mounted) {
      setState(() {
        _packages = packages.where((p) =>
          p.packageType == PackageType.monthly ||
          p.packageType == PackageType.annual
        ).toList();
        _loading = false;
      });
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() { _purchasing = true; _error = null; });
    final success = await RevenueCatService.purchase(package);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Welcome to LastWish PRO! 🎉'),
        backgroundColor: Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      setState(() {
        _purchasing = false;
        _error = 'Purchase failed. Please try again.';
      });
    }
  }

  Future<void> _restore() async {
    setState(() { _purchasing = true; _error = null; });
    final success = await RevenueCatService.restore();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PRO restored successfully!'),
        backgroundColor: Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      setState(() {
        _purchasing = false;
        _error = 'No active subscription found.';
      });
    }
  }

  String _packageLabel(Package p) {
    final price = p.storeProduct.priceString;
    if (p.packageType == PackageType.annual) return 'Yearly · $price';
    if (p.packageType == PackageType.monthly) return 'Monthly · $price';
    return p.storeProduct.title;
  }

  String? _packageSavings(Package p) {
    if (p.packageType != PackageType.annual) return null;
    final monthly = _packages.firstWhere(
      (x) => x.packageType == PackageType.monthly,
      orElse: () => p,
    );
    if (monthly == p) return null;
    final annualMonthly = p.storeProduct.price / 12;
    final savings = ((1 - annualMonthly / monthly.storeProduct.price) * 100).round();
    return savings > 0 ? 'Save $savings%' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF2D1B69)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 20)],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),

            const Text('LastWish PRO',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(widget.reason,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 20),

            // Features
            _FeatureRow(icon: Icons.people_alt_outlined,       text: 'Unlimited guardians & protected persons'),
            _FeatureRow(icon: Icons.notifications_active_outlined, text: 'Ring alarm button'),
            _FeatureRow(icon: Icons.schedule_outlined,         text: 'Will delivery 1–6 days'),
            _FeatureRow(icon: Icons.timer_outlined,            text: 'Shorter check-in intervals'),
            const SizedBox(height: 20),

            // Packages
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: Color(0xFF7C3AED), strokeWidth: 2),
              )
            else if (_packages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No packages available', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              )
            else
              Column(
                children: _packages.map((p) {
                  final savings = _packageSavings(p);
                  final isAnnual = p.packageType == PackageType.annual;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _purchasing ? null : () => _purchase(p),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: isAnnual ? const Color(0xFF7C3AED) : Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          side: isAnnual ? null : BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: _purchasing
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_packageLabel(p), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (savings != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(savings, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),

            // Restore + dismiss
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _purchasing ? null : _restore,
                  child: Text('Restore purchases',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Maybe later',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: const Color(0xFFB794F4)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          const Icon(Icons.check_circle, size: 15, color: Color(0xFF7C3AED)),
        ],
      ),
    );
  }
}
