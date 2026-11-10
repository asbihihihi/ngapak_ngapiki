import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (_url.isEmpty && _publishableKey.isEmpty) {
      debugPrint('Supabase is not configured; continuing with local Hive data.');
      return;
    }

    if (_url.isEmpty || _publishableKey.isEmpty) {
      throw StateError(
        'Set both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY using '
        '--dart-define before starting the app.',
      );
    }

    await Supabase.initialize(url: _url, publishableKey: _publishableKey);
  }
}
