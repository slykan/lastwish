import 'package:flutter/material.dart';

class QuickStats extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? status;
  final int protectedCount;

  const QuickStats({
    super.key,
    required this.user,
    required this.status,
    this.protectedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?['name'] ?? '-';
    final city = status?['city'] ?? user?['city'];
    final country = status?['country'] ?? user?['country'];
    final location = [city, country].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    final locationLabel = location.isNotEmpty ? location : 'Unknown';
    // protectedCount dolazi izvana (protectedPeople.length)
    final interval = user?['alive_interval_hours'] ?? 24;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _item(Icons.account_circle_outlined, 'User', name),
          _item(Icons.supervised_user_circle_outlined, 'Protected', '$protectedCount people'),
          _item(Icons.timer_outlined, 'Check interval', '${interval}h'),
          _item(Icons.location_on_outlined, 'Location', locationLabel),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}