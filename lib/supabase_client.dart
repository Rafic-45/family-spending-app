import 'package:supabase_flutter/supabase_flutter.dart';

/// Shortcut to the initialized Supabase client used across the app.
SupabaseClient get supabase => Supabase.instance.client;
