import 'package:flutter/material.dart';
import 'package:lastwish/services/api_service.dart';
import 'invite_dialog.dart';

class SentInvitesWidget extends StatefulWidget {
  const SentInvitesWidget({super.key});

  @override
  State<SentInvitesWidget> createState() => _SentInvitesWidgetState();
}

class _SentInvitesWidgetState extends State<SentInvitesWidget> {
  List<dynamic> _invites = [];
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.fetchSentInvites();
    if (mounted) setState(() {
      _invites = data;
      _loading = false;
    });
  }

  Future<void> _invite(String role) async {
    final sent = await showInviteDialog(context, role: role);
    if (sent == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invitation sent'),
            backgroundColor: const Color(0xFF1E7E34),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with invite buttons ──
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.send_outlined, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Invite',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InviteButton(
                        icon: Icons.shield_outlined,
                        label: 'Invite Guardian',
                        onTap: () => _invite('guardian'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InviteButton(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Invite Protected',
                        onTap: () => _invite('protected'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Sent invitations toggle ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(_expanded ? 0 : 20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.history, size: 15, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 8),
                  Text(
                    'Sent invitations${_invites.isNotEmpty ? ' (${_invites.length})' : ''}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),

          // ── Sent invitations list ──
          if (_expanded) ...[
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white38, strokeWidth: 2),
                      ),
                    )
                  : _invites.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No invitations sent yet',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 13),
                          ),
                        )
                      : SizedBox(
                          height: (_invites.length > 3 ? 3 : _invites.length) * 68.0,
                          child: ListView.builder(
                            itemCount: _invites.length,
                            itemBuilder: (context, index) {
                            final invite = _invites[index] as Map<String, dynamic>;
                            final email = invite['email']?.toString() ?? '-';
                            final role = (invite['intended_role'] ?? invite['role'])?.toString() ?? '';
                            final rawDate = invite['created_at']?.toString() ?? '';
                            String createdAt = '';
                            if (rawDate.isNotEmpty) {
                              try {
                                final dt = DateTime.parse(rawDate).toLocal();
                                createdAt =
                                    '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                              } catch (_) {
                                createdAt = rawDate;
                              }
                            }
                            final status = invite['status']?.toString() ?? 'pending';
                            final isPending = status == 'pending';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.07)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPending
                                        ? Icons.schedule
                                        : Icons.check_circle_outline,
                                    size: 14,
                                    color: isPending
                                        ? const Color(0xFFFFC857)
                                        : const Color(0xFF5BFF6A),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          email,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7B4FD4)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                role,
                                                style: const TextStyle(
                                                  color: Color(0xFF9B7FE4),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (createdAt.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  createdAt,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.35),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isPending
                                              ? const Color(0xFFFFC857)
                                              : const Color(0xFF5BFF6A))
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: isPending
                                            ? const Color(0xFFFFC857)
                                            : const Color(0xFF5BFF6A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InviteButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF7B4FD4).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF7B4FD4).withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF9B7FE4)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9B7FE4),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
