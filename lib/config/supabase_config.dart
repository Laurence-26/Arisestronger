/// Supabase project credentials.
///
/// These can be overridden at build time with:
///   --dart-define=SUPABASE_URL=...  --dart-define=SUPABASE_KEY=...
///
/// The publishable / anon key is SAFE to ship inside a client app — Row Level
/// Security (see supabase/schema.sql) is what actually protects user data.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gtcztafphmtnyopofeze.supabase.co',
  );

  /// New-format publishable key (sb_publishable_...) or legacy anon key.
  static const String key = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable__9bpOaBE2BgIVgzyCtROBA_kqqt9q_G',
  );

  /// Deep-link scheme used for OAuth (Google) redirects back into the app.
  /// Must match the intent-filter in AndroidManifest.xml and the
  /// CFBundleURLSchemes entry in ios/Runner/Info.plist, and be added to
  /// Supabase → Authentication → URL Configuration → Redirect URLs.
  static const String oauthRedirect = 'com.sldq.dailyquest://login-callback/';

  static bool get isConfigured => url.startsWith('http') && key.length > 20;
}
