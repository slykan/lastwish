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
    final interval = user?['alive_interval_hours'] ?? 24;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(child: _item(Icons.supervised_user_circle_outlined, 'Protected', '$protectedCount people')),
          const SizedBox(width: 12),
          Expanded(child: _item(Icons.timer_outlined, 'Check interval', '${interval}h')),
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