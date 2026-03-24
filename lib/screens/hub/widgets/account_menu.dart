import 'package:flutter/material.dart';

class AccountMenu extends StatelessWidget {
  final String? userName;
  final String? email;
  final String? provider;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onIntervals;
  final VoidCallback? onLogout;

  const AccountMenu({
    super.key,
    this.userName,
    this.email,
    this.provider,
    this.onProfile,
    this.onSettings,
    this.onIntervals,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _menuItem(
              icon: Icons.person,
              text: 'Profile',
              onTap: onProfile,
            ),
            _menuItem(
              icon: Icons.settings,
              text: 'Settings',
              onTap: onSettings,
            ),
            _menuItem(
              icon: Icons.access_alarm,
              text: 'Intervals',
              onTap: onIntervals,
            ),
            _menuItem(
              icon: Icons.logout,
              text: 'Log out',
              color: Colors.red,
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 20),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
