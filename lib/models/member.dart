/// A family member (a row in `profiles`).
class Member {
  final String id;
  final String displayName;

  const Member({required this.id, required this.displayName});

  factory Member.fromMap(Map<String, dynamic> map) => Member(
        id: map['id'] as String,
        displayName: (map['display_name'] as String?) ?? 'Someone',
      );
}
