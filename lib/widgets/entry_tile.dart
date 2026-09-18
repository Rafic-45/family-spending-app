import 'package:flutter/material.dart';

import '../format.dart';
import '../models/entry.dart';

/// One row in the shared feed, e.g.
///   💸  Rafic spent $45.00 on Groceries — Sep 18
///   🔄  Rafic sent $100.00 to Karim (Allowance) — Sep 18
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.actorName,
    this.recipientName,
  });

  final Entry entry;
  final String actorName;
  final String? recipientName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTransfer = entry.isTransfer;
    final accent = isTransfer ? theme.colorScheme.tertiary : theme.colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.15),
        child: Text(isTransfer ? '🔄' : '💸', style: const TextStyle(fontSize: 20)),
      ),
      title: Text.rich(
        _sentence(theme),
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          formatDate(entry.occurredOn),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ),
      trailing: entry.photoUrl == null
          ? null
          : _Thumbnail(url: entry.photoUrl!),
    );
  }

  TextSpan _sentence(ThemeData theme) {
    final bold = TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface);
    final amount = formatAmount(entry.amount);
    final note = (entry.note != null && entry.note!.trim().isNotEmpty)
        ? entry.note!.trim()
        : null;

    if (entry.isTransfer) {
      final to = recipientName ?? 'a family member';
      return TextSpan(children: [
        TextSpan(text: actorName, style: bold),
        const TextSpan(text: ' sent '),
        TextSpan(text: amount, style: bold),
        const TextSpan(text: ' to '),
        TextSpan(text: to, style: bold),
        if (note != null) TextSpan(text: ' ($note)'),
      ]);
    }
    return TextSpan(children: [
      TextSpan(text: actorName, style: bold),
      const TextSpan(text: ' spent '),
      TextSpan(text: amount, style: bold),
      if (note != null) ...[
        const TextSpan(text: ' on '),
        TextSpan(text: note, style: bold),
      ],
    ]);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}
