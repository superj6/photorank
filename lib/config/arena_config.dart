/// Supabase connection for Arena. Injected at build time so no key lives in
/// the repo:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
/// With no values the Arena tab shows an "not configured" state and the rest
/// of the app is unaffected.
class ArenaConfig {
  ArenaConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get configured => url.isNotEmpty && anonKey.isNotEmpty;

  static const bucket = 'entries';
  static const duelsPerRound = 10;
  static const maxDuelsPerDay = 50;
}
