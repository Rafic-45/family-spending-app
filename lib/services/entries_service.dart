import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entry.dart';
import '../supabase_client.dart';

/// Creates entries, uploads receipt photos, and streams the live feed.
class EntriesService {
  /// A live stream of a family's entries, newest first. New rows arrive in real
  /// time via Supabase Realtime.
  Stream<List<Entry>> feed(String familyId) {
    return supabase
        .from('entries')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Entry.fromMap).toList());
  }

  Future<void> addExpense({
    required String familyId,
    required double amount,
    required DateTime date,
    String? note,
    String? photoUrl,
  }) async {
    await supabase.from('entries').insert({
      'family_id': familyId,
      'user_id': _uid,
      'type': 'expense',
      'amount': amount,
      'occurred_on': _dateOnly(date),
      'note': _clean(note),
      'photo_url': photoUrl,
    });
  }

  Future<void> addTransfer({
    required String familyId,
    required double amount,
    required DateTime date,
    required String recipientId,
    String? note,
    String? photoUrl,
  }) async {
    await supabase.from('entries').insert({
      'family_id': familyId,
      'user_id': _uid,
      'type': 'transfer',
      'amount': amount,
      'occurred_on': _dateOnly(date),
      'recipient_id': recipientId,
      'note': _clean(note),
      'photo_url': photoUrl,
    });
  }

  /// Uploads a receipt into the family's storage folder and returns its public URL.
  Future<String> uploadReceipt({
    required String familyId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ext = (fileExtension.isEmpty ? 'jpg' : fileExtension).toLowerCase();
    final path = '$familyId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage.from('receipts').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeFor(ext), upsert: true),
        );
    return supabase.storage.from('receipts').getPublicUrl(path);
  }

  String get _uid => supabase.auth.currentUser!.id;

  String _dateOnly(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  String _mimeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
