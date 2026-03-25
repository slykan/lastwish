import 'package:flutter/material.dart';
import 'package:lastwish/services/api_service.dart';
import 'package:lastwish/widgets/pro_upgrade_modal.dart';

/// Shows the invite dialog. [role] = 'guardian' or 'protected'.
/// [sentInvites] = already sent invites to check for duplicates.
/// Returns true if invite was sent successfully.
Future<bool?> showInviteDialog(BuildContext context,
    {required String role, List<dynamic> sentInvites = const []}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _InviteDialog(role: role, sentInvites: sentInvites),
  );
}

class _InviteDialog extends StatefulWidget {
  final String role;
  final List<dynamic> sentInvites;
  const _InviteDialog({required this.role, this.sentInvites = const []});

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _alreadySent = false;

  String get _title => widget.role == 'guardian'
      ? 'Invite a Guardian'
      : 'Invite Protected Person';

  String get _hint => widget.role == 'guardian'
      ? 'Guardian\'s email address'
      : 'Protected person\'s email address';

  String get _description => widget.role == 'guardian'
      ? 'They will receive an email and can accept the invitation to become your guardian.'
      : 'They will receive an email and can accept the invitation to be protected by you.';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    // Check for existing pending invite to this email
    final duplicate = widget.sentInvites.any((inv) {
      final invEmail = (inv['email']?.toString() ?? '').toLowerCase();
      final invRole = (inv['role']?.toString() ?? '');
      final status = (inv['status']?.toString() ?? '');
      return invEmail == email && invRole == widget.role && status == 'pending';
    });
    if (duplicate) {
      setState(() {
        _error = 'A pending invitation was already sent to this email.';
        _alreadySent = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.sendInvite(email, widget.role);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else if (result['upgrade_required'] == true) {
      Navigator.pop(context, false);
      ProUpgradeModal.show(context, 'Free plan allows only 1 guardian. Upgrade to PRO for unlimited.');
    } else {
      setState(() {
        _loading = false;
        _error = result['message']?.toString() ?? 'Failed to send invitation';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1030),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.role == 'guardian'
                      ? Icons.shield_outlined
                      : Icons.person_add_alt_1_outlined,
                  color: const Color(0xFF7B4FD4),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: _hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                prefixIcon: Icon(Icons.email_outlined,
                    color: Colors.white.withOpacity(0.4), size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B4FD4)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E5E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFF5E5E).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFFF5E5E), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Color(0xFFFF5E5E), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B4FD4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Send invite',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
