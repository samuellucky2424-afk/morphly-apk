import '../models/user_settings.dart';
import '../services/supabase_gateway.dart';

class SettingsRepository {
  const SettingsRepository({this.gateway = const SupabaseGateway()});

  final SupabaseGateway gateway;

  Future<UserSettings> fetch() async {
    if (!gateway.isConfigured || gateway.client.auth.currentUser == null) {
      return UserSettings.defaults;
    }

    final result = await gateway.client
        .from('user_settings_r')
        .select()
        .eq('user_id', gateway.userId)
        .maybeSingle();

    return UserSettings.fromJson(result);
  }

  Future<void> save(UserSettings settings) async {
    if (!gateway.isConfigured || gateway.client.auth.currentUser == null) {
      return;
    }

    await gateway.client
        .from('user_settings_r')
        .upsert(settings.toJson(gateway.userId));
  }
}
