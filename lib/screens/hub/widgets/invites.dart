import 'package:flutter/material.dart';

class InvitesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> invites;
  final void Function(Map<String, dynamic>)? onAccept;
  final void Function(Map<String, dynamic>)? onDecline;

  const InvitesWidget({
    super.key,
    required this.invites,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_add_alt_1, color: Color(0xFFFFC857), size: 20),
              SizedBox(width: 8),
              Text(
                'Received invitations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...invites.map((invite) => _InviteRow(
                invite: invite,
                onAccept: onAccept,
                onDecline: onDecline,
              )),
        ],
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  final Map<String, dynamic> invite;
  final void Function(Map<String, dynamic>)? onAccept;
  final void Function(Map<String, dynamic>)? onDecline;

  const _InviteRow({
    required this.invite,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final name = invite['name'] ?? '-';
    final message = invite['message'] ?? 'wants you as their guardian.';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAccept != null ? () => onAccept!(invite) : null,
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.18),
                    foregroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDecline != null ? () => onDecline!(invite) : null,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  label: const Text('Decline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.18),
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
