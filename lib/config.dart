/// Connection settings for the "family-spend" Supabase project.
///
/// The anon key below is a *public*, RLS-protected client key. It is designed to
/// ship inside client apps — every real access-control decision is enforced by
/// the database's row level security policies, not by keeping this key secret.
class AppConfig {
  const AppConfig._();

  /// Supabase project URL.
  static const String supabaseUrl = 'https://jqdgzeteqghqdozqxlmu.supabase.co';

  /// Public anon key (safe to embed in the app).
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZGd6ZXRlcWdocWRvenF4bG11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk3MTgyMDMsImV4cCI6MjEwNTI5NDIwM30.UoS4XdkPIVeiBTo0Tf4pnWZPtlQWfEyfDADR80ZmLcE';

  /// Symbol shown in front of amounts (e.g. "$45.00").
  static const String currencySymbol = '\$';

  /// Family members sign in with just a name + password. Under the hood the
  /// name becomes a synthetic email at this domain — members never see it.
  static const String authEmailDomain = 'familyspend.local';
}
