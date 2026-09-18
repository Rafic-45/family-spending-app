import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../supabase_client.dart';

/// Name + password auth. The name is mapped to a synthetic email so we can use
/// Supabase's email/password auth without ever asking the family for an email.
class AuthService {
  /// Turn a member's name into a stable, unique-ish email.
  /// "Karim" -> "karim@familyspend.local", "Rafic H." -> "rafic.h@familyspend.local".
  static String emailForName(String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    final safe = slug.isEmpty ? 'member' : slug;
    return '$safe@${AppConfig.authEmailDomain}';
  }

  Session? get currentSession => supabase.auth.currentSession;

  Future<void> signUp({required String name, required String password}) async {
    final email = emailForName(name);
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': name.trim()},
    );
    // Accounts are auto-confirmed in the database, so sign-up normally returns a
    // session immediately. If it didn't, sign in so the user lands logged in.
    if (res.session == null) {
      await supabase.auth.signInWithPassword(email: email, password: password);
    }
  }

  Future<void> signIn({required String name, required String password}) async {
    await supabase.auth.signInWithPassword(
      email: emailForName(name),
      password: password,
    );
  }

  Future<void> signOut() => supabase.auth.signOut();
}
