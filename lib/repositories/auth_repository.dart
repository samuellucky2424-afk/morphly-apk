import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_gateway.dart';

class AuthRepository {
  const AuthRepository({this.gateway = const SupabaseGateway()});

  final SupabaseGateway gateway;

  User? get currentUser {
    if (!gateway.isConfigured) return null;
    return gateway.client.auth.currentUser;
  }

  Stream<AuthState> get authChanges {
    return gateway.client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return gateway.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return gateway.client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) {
    return gateway.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() => gateway.client.auth.signOut();
}
