import '../models/family.dart';
import '../models/member.dart';
import '../supabase_client.dart';

/// Reads and writes around families and their members.
class FamilyService {
  /// The signed-in user's family id, or null if they haven't joined one yet.
  Future<String?> currentFamilyId() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await supabase
        .from('profiles')
        .select('family_id')
        .eq('id', uid)
        .maybeSingle();
    return row?['family_id'] as String?;
  }

  Future<Family> createFamily(String name) async {
    final data = await supabase.rpc('create_family', params: {'family_name': name});
    return Family.fromMap(_firstRow(data));
  }

  Future<Family> joinFamily(String code) async {
    final data = await supabase.rpc('join_family', params: {'code': code});
    return Family.fromMap(_firstRow(data));
  }

  Future<Family> getFamily(String familyId) async {
    final row =
        await supabase.from('families').select().eq('id', familyId).single();
    return Family.fromMap(row);
  }

  Future<List<Member>> members(String familyId) async {
    final rows = await supabase
        .from('profiles')
        .select('id, display_name')
        .eq('family_id', familyId)
        .order('display_name');
    return (rows as List)
        .map((r) => Member.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _firstRow(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return data.first as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    throw StateError('Unexpected response from the server.');
  }
}
