import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GuardiansWidget extends StatelessWidget {
  final List<Map<String, dynamic>>? guardians;
  final VoidCallback? onInviteGuardian;
  final void Function(Map<String, dynamic>)? onRemoveGuardian;

  const GuardiansWidget({
    super.key,
    this.guardians,
    this.onInviteGuardian,
    this.onRemoveGuardian,
  });

  @override
  Widget build(BuildContext context) {
    final list = guardians ?? [];
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
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Your guardians',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No guardians yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: list.map((g) => _GuardianRow(
                  guardian: g,
                  onRemove: onRemoveGuardian,
                )).toList(),
              ),
            ),
          const SizedBox(height: 18),
          Center(
            child: ElevatedButton.icon(
              onPressed: onInviteGuardian,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Invite a person you want to protect you (Guardian)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.10),
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                textStyle: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardianRow extends StatefulWidget {
  final Map<String, dynamic> guardian;
  final void Function(Map<String, dynamic>)? onRemove;

  const _GuardianRow({required this.guardian, this.onRemove});

  @override
  State<_GuardianRow> createState() => _GuardianRowState();
}

class _GuardianRowState extends State<_GuardianRow> {
  bool _removing = false;

  Future<void> _confirm() async {
    final name = widget.guardian['name'] ?? 'this guardian';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove guardian',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Remove $name from your guardians?',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFFF5E5E))),
          ),
        ],
      ),
    );
    if (confirmed == true && widget.onRemove != null) {
      setState(() => _removing = true);
      widget.onRemove!(widget.guardian);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.guardian['name'] ?? '-';
    final phone = widget.guardian['phone'] ?? '';
    final email = widget.guardian['email'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.white60),
              const SizedBox(width: 6),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              if (phone.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.phone_android, size: 15, color: Colors.white),
                const SizedBox(width: 2),
                Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ],
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_box_outlined, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Guardian', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              if (phone.isNotEmpty) ...[  
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  icon: const Icon(Icons.phone_outlined, size: 14),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5BFF6A),
                    side: BorderSide(color: const Color(0xFF5BFF6A).withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: _removing ? null : _confirm,
                icon: _removing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(Icons.close, size: 16),
                label: const Text('Remove'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.18),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
