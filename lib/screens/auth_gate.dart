import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/family_service.dart';
import '../supabase_client.dart';
import 'auth_screen.dart';
import 'feed_screen.dart';
import 'onboarding_screen.dart';

/// Top-level router: shows the sign-in screen when logged out, otherwise the
/// family gate. Rebuilds automatically whenever auth state changes.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        final session = supabase.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }
        // Key by user id so switching accounts rebuilds the gate from scratch.
        return FamilyGate(key: ValueKey(session.user.id));
      },
    );
  }
}

/// Decides between onboarding (no family yet) and the feed (has a family).
class FamilyGate extends StatefulWidget {
  const FamilyGate({super.key});

  @override
  State<FamilyGate> createState() => _FamilyGateState();
}

class _FamilyGateState extends State<FamilyGate> {
  final _familyService = FamilyService();
  late Future<String?> _familyIdFuture;

  @override
  void initState() {
    super.initState();
    _familyIdFuture = _familyService.currentFamilyId();
  }

  void _reload() {
    setState(() {
      _familyIdFuture = _familyService.currentFamilyId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _familyIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final familyId = snapshot.data;
        if (familyId == null) {
          return OnboardingScreen(onJoined: _reload);
        }
        return FeedScreen(familyId: familyId);
      },
    );
  }
}
