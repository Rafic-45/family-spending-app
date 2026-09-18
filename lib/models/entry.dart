/// A single ledger entry — either an expense or a transfer.
class Entry {
  final String id;
  final String type; // 'expense' | 'transfer'
  final double amount;
  final DateTime occurredOn;
  final String userId; // who logged it
  final DateTime createdAt;
  final String? note;
  final String? recipientId; // transfers only
  final String? photoUrl;

  const Entry({
    required this.id,
    required this.type,
    required this.amount,
    required this.occurredOn,
    required this.userId,
    required this.createdAt,
    this.note,
    this.recipientId,
    this.photoUrl,
  });

  bool get isTransfer => type == 'transfer';

  factory Entry.fromMap(Map<String, dynamic> map) => Entry(
        id: map['id'] as String,
        type: map['type'] as String,
        amount: _toDouble(map['amount']),
        occurredOn: DateTime.parse(map['occurred_on'] as String),
        userId: map['user_id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        note: map['note'] as String?,
        recipientId: map['recipient_id'] as String?,
        photoUrl: map['photo_url'] as String?,
      );

  // Postgres `numeric` can arrive as a number or a string, depending on size.
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
