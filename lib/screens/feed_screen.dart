import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entry.dart';
import '../models/family.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/entries_service.dart';
import '../services/family_service.dart';
import '../supabase_client.dart';
import '../widgets/entry_tile.dart';
import 'add_entry_screen.dart';

/// The home screen: a live, shared feed of the family's expenses and transfers.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _familyService = FamilyService();
  final _entriesService = EntriesService();
  final _auth = AuthService();

  Family? _family;
  Map<String, String> _names = {};
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final family = await _familyService.getFamily(widget.familyId);
      final members = await _familyService.members(widget.familyId);
      if (!mounted) return;
      setState(() {
        _family = family;
        _names = {for (final m in members) m.id: m.displayName};
        _loadingMeta = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMeta = false);
    }
  }

  Future<void> _copyInviteCode() async {
    final code = _family?.inviteCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite code $code copied')),
    );
  }

  Future<void> _openAddEntry() async {
    final me = supabase.auth.currentUser?.id;
    final recipients = _names.entries
        .where((e) => e.key != me)
        .map((e) => Member(id: e.key, displayName: e.value))
        .toList();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddEntryScreen(
          familyId: widget.familyId,
          recipients: recipients,
        ),
      ),
    );
    // Refresh names in case someone new joined while we were away.
    _loadMeta();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_family?.name ?? 'Family Spend'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _auth.signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_loadingMeta && _family != null) _inviteBanner(context),
            Expanded(child: _feedList()),
          ],
        ),
      ),
    );
  }

  Widget _inviteBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite code',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  _family!.inviteCode,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _copyInviteCode,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Widget _feedList() {
    return StreamBuilder<List<Entry>>(
      stream: _entriesService.feed(widget.familyId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(
            Icons.error_outline,
            "Couldn't load the feed.",
            '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return _message(
            Icons.receipt_long_outlined,
            'No entries yet',
            'Tap “Add” to log your first expense or transfer.',
          );
        }
        return RefreshIndicator(
          onRefresh: _loadMeta,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final entry = entries[i];
              return EntryTile(
                entry: entry,
                actorName: _names[entry.userId] ?? 'Someone',
                recipientName: entry.recipientId == null
                    ? null
                    : _names[entry.recipientId],
              );
            },
          ),
        );
      },
    );
  }

  Widget _message(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
