import 'package:flutter/material.dart';

class QuickStats extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? status;

  const QuickStats({
    super.key,
    required this.user,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?['name'] ?? '-';
    final city = status?['city'] ?? 'Unknown';
    final protectedCount = user?['guardian_count'] ?? 0;
    final interval = user?['alive_interval_hours'] ?? 24;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item(Icons.person, name),
          _item(Icons.shield, "$protectedCount Protected"),
          _item(Icons.timer, "${interval}h Check"),
          _item(Icons.location_on, city),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}