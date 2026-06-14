import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_config.dart';

class SupabaseNotConfiguredException implements Exception {
  const SupabaseNotConfiguredException();

  @override
  String toString() {
    return 'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.';
  }
}

class SupabaseGateway {
  const SupabaseGateway();

  bool get isConfigured => AppConfig.hasSupabase;

  SupabaseClient get client {
    if (!isConfigured) throw const SupabaseNotConfiguredException();
    return Supabase.instance.client;
  }

  String get userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated Morphly user.');
    return id;
  }
}
