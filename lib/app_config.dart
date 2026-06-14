class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iwausfzgitoehqecrvxc.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3YXVzZnpnaXRvZWhxZWNydnhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MDk2NTAsImV4cCI6MjA5MDA4NTY1MH0.PVBpPN-j6C8_ojhuC7AbNB7uuKYe4H7z7bCAW2pfddc',
  );
  static const decartModel = String.fromEnvironment(
    'DECART_MODEL',
    defaultValue: 'lucy-latest',
  );
  static const releaseChannel = String.fromEnvironment(
    'RELEASE_CHANNEL',
    defaultValue: 'store',
  );
  static const vercelApiBaseUrl = String.fromEnvironment(
    'VERCEL_API_BASE_URL',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasVercelBackend => vercelApiBaseUrl.isNotEmpty;

  static bool get isOffStoreAndroid => releaseChannel == 'off_store_android';
}
