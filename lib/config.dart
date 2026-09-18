/// Connection settings for the "family-spend" Supabase project.
///
/// The publishable key below is a *public*, RLS-protected client key. It is
/// designed to ship inside client apps — every real access-control decision is
/// enforced by the database's row level security policies, not by keeping this
/// key secret.
class AppConfig {
  const AppConfig._();

  /// Supabase project URL.
  static const String supabaseUrl = 'https://jqdgzeteqghqdozqxlmu.supabase.co';

  /// Public publishable key (safe to embed in the app).
  static const String supabasePublishableKey =
      'sb_publishable_4F6_maUcWsfNT5mJsrNxZQ_qgqcUprA';

  /// Symbol shown in front of amounts (e.g. "$45.00").
  static const String currencySymbol = '\$';

  /// Family members sign in with just a name + password. Under the hood the
  /// name becomes a synthetic email at this domain — members never see it.
  static const String authEmailDomain = 'familyspend.local';
}
