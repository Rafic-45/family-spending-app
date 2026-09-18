/// A household (a row in `families`), identified by a short invite code.
class Family {
  final String id;
  final String name;
  final String inviteCode;

  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  factory Family.fromMap(Map<String, dynamic> map) => Family(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? 'My Family',
        inviteCode: (map['invite_code'] as String?) ?? '',
      );
}
