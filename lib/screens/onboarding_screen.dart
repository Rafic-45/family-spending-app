import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/family_service.dart';

/// Shown once, right after a member first signs up: create a new family or join
/// an existing one with its invite code.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onJoined});

  /// Called after the user successfully creates or joins a family.
  final VoidCallback onJoined;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Mode { create, join }

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _familyService = FamilyService();
  final _auth = AuthService();
  final _familyNameController = TextEditingController();
  final _codeController = TextEditingController();

  _Mode _mode = _Mode.create;
  bool _loading = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_mode == _Mode.create) {
        final name = _familyNameController.text.trim();
        if (name.isEmpty) {
          throw 'Give your family a name.';
        }
        await _familyService.createFamily(name);
      } else {
        final code = _codeController.text.trim();
        if (code.isEmpty) {
          throw 'Enter the invite code.';
        }
        await _familyService.joinFamily(code);
      }
      if (!mounted) return;
      widget.onJoined();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendly(e))),
      );
    }
  }

  String _friendly(Object error) {
    final text = error.toString();
    if (text.contains('No family found')) {
      return "That invite code didn't match any family.";
    }
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreate = _mode == _Mode.create;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your family'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _loading ? null : _auth.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_Mode>(
                  segments: const [
                    ButtonSegment(
                      value: _Mode.create,
                      icon: Icon(Icons.add_home_outlined),
                      label: Text('Create'),
                    ),
                    ButtonSegment(
                      value: _Mode.join,
                      icon: Icon(Icons.group_add_outlined),
                      label: Text('Join'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _loading
                      ? null
                      : (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 24),
                Text(
                  isCreate
                      ? 'Start a new family ledger. You’ll get an invite code to share with everyone else.'
                      : 'Ask whoever created your family for their invite code, then enter it below.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (isCreate)
                  TextField(
                    controller: _familyNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Family name',
                      hintText: 'e.g. The Hariris',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  )
                else
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Invite code',
                      hintText: 'e.g. 4F9A2C',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isCreate ? 'Create family' : 'Join family'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
