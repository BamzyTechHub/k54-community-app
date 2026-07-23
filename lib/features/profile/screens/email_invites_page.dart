import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

class _RecipientRow {
  final TextEditingController nameController;
  final TextEditingController emailController;

  _RecipientRow() : nameController = TextEditingController(), emailController = TextEditingController();

  void dispose() {
    nameController.dispose();
    emailController.dispose();
  }
}

/// Profile's "Email Invites" tab, matching the Figma design's repeating
/// recipient-row form. Wired to the real, confirmed `/buddyboss/v1/invites`
/// endpoint (schema checked live 2026-07-18) - BuddyBoss's own site-wide
/// "invite someone by email" feature, distinct from group invites, and
/// its `fields` array natively takes multiple recipients in one request
/// (matches this form's add-a-row design exactly, not a guess). The
/// "Generate text with AI" pill is left as an honest "not available yet"
/// tap - the k54-ai/v1 backend has no confirmed endpoint for drafting
/// invite copy specifically.
class EmailInvitesForm extends StatefulWidget {
  const EmailInvitesForm({super.key});

  @override
  State<EmailInvitesForm> createState() => _EmailInvitesFormState();
}

class _EmailInvitesFormState extends State<EmailInvitesForm> {
  final BuddyBossService _service = BuddyBossService();
  final _messageController = TextEditingController();
  final List<_RecipientRow> _rows = [_RecipientRow(), _RecipientRow()];

  List<Map<String, dynamic>>? _invites;
  bool _loadingInvites = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    setState(() => _loadingInvites = true);
    try {
      _invites = await _service.getInvites();
    } catch (_) {
      _invites = [];
    } finally {
      if (mounted) setState(() => _loadingInvites = false);
    }
  }

  void _addRow() => setState(() => _rows.add(_RecipientRow()));

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  Future<void> _send() async {
    final recipients = _rows
        .map((r) => (name: r.nameController.text.trim(), email: r.emailController.text.trim()))
        .where((r) => r.name.isNotEmpty && r.email.isNotEmpty)
        .toList();

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter at least one recipient name and email")),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _service.sendInvites(recipients: recipients, message: _messageController.text.trim());
      if (!mounted) return;
      for (final row in _rows) {
        row.dispose();
      }
      setState(() {
        _rows
          ..clear()
          ..addAll([_RecipientRow(), _RecipientRow()]);
        _messageController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invite${recipients.length > 1 ? 's' : ''} sent")),
      );
      await _loadInvites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't send invite: $e")),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Send Invites", style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.green)),
        const SizedBox(height: 6),
        Text(
          "Invite non-members to create an account. They will receive an email with a link to register.",
          style: GoogleFonts.lato(fontSize: 13, color: AppColors.greyShade700),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF8ED),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Persistent column headers above the rows - previously
              // missing; the field hint text alone disappeared once the
              // user typed, unlike Figma's always-visible "Recipient
              // Name" / "Recipient Email" labels.
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Recipient Name", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text("Recipient Email", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              for (int i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _pillField(hint: "Recipient Name", controller: _rows[i].nameController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _pillField(
                          hint: "Recipient Email",
                          controller: _rows[i].emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      if (_rows.length > 1) ...[
                        const SizedBox(width: 4),
                        TapScale(
                          onTap: () => _removeRow(i),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 16, color: AppColors.grey),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TapScale(
                  onTap: _addRow,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: AppColors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Text(
          "Customize the text of the invitation email. A link to register will be sent with the email.",
          style: GoogleFonts.lato(fontSize: 12, color: AppColors.greyShade700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          minLines: 7,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: "Write about yourself...",
            hintStyle: TextStyle(color: AppColors.green.withValues(alpha: 0.7)),
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(14),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.greyShade300)),
          ),
        ),
        const SizedBox(height: 10),
        // Plain text+icon link, not a bordered pill - matches the
        // screenshot's minimal "Generate text with AI" treatment.
        TapScale(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Generating invite text with AI isn't available yet")),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.green),
              const SizedBox(width: 5),
              Text(
                "Generate text with AI",
                style: GoogleFonts.lato(fontSize: 12, color: AppColors.green, decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Compact right-aligned pill, not a full-width primary button -
        // matches the screenshot exactly.
        Align(
          alignment: Alignment.centerRight,
          child: PressablePill(label: "Send Invites", onTap: _sending ? null : _send, loading: _sending),
        ),
        const SizedBox(height: 24),
        Text("Sent Invites", style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_loadingInvites)
          const Center(child: CircularProgressIndicator(color: AppColors.green))
        else if ((_invites ?? []).isEmpty)
          Text("No invites sent yet", style: GoogleFonts.lato(color: AppColors.greyShade600))
        else
          ...(_invites ?? []).map((invite) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EFD9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((invite["name"] ?? "").toString(), style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                          Text(
                            (invite["email"] ?? "").toString(),
                            style: GoogleFonts.lato(fontSize: 12, color: AppColors.greyShade700),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      (invite["status"] ?? "").toString(),
                      style: GoogleFonts.lato(fontSize: 12, color: AppColors.green),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _pillField({required String hint, required TextEditingController controller, TextInputType? keyboardType}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: AppColors.greyShade500),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
