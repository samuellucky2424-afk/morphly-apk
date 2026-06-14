import '../models/credit_package.dart';
import '../models/morph_session.dart';
import '../services/edge_function_client.dart';
import '../services/supabase_gateway.dart';

class CreditsRepository {
  const CreditsRepository({
    this.gateway = const SupabaseGateway(),
    this.functions = const EdgeFunctionClient(),
  });

  final SupabaseGateway gateway;
  final EdgeFunctionClient functions;

  Future<int> fetchBalance() async {
    if (!gateway.isConfigured || gateway.client.auth.currentUser == null) {
      return 0;
    }
    final value = await gateway.client.rpc('get_credit_balance');
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<List<CreditPackage>> fetchPackages() async {
    if (!gateway.isConfigured) {
      return const [
        CreditPackage(
          id: 'demo-50',
          code: 'credits_50',
          credits: 50,
          priceMinor: 100000,
          currency: 'NGN',
          isPopular: false,
          flutterwaveEnabled: true,
        ),
        CreditPackage(
          id: 'demo-120',
          code: 'credits_120',
          credits: 120,
          priceMinor: 200000,
          currency: 'NGN',
          isPopular: true,
          flutterwaveEnabled: true,
        ),
        CreditPackage(
          id: 'demo-350',
          code: 'credits_350',
          credits: 350,
          priceMinor: 500000,
          currency: 'NGN',
          isPopular: false,
          flutterwaveEnabled: true,
        ),
        CreditPackage(
          id: 'demo-800',
          code: 'credits_800',
          credits: 800,
          priceMinor: 1000000,
          currency: 'NGN',
          isPopular: false,
          flutterwaveEnabled: true,
        ),
      ];
    }

    final rows = await gateway.client
        .from('credit_packages_r')
        .select()
        .eq('active', true)
        .order('sort_order');

    return rows
        .map<CreditPackage>(
          (row) => CreditPackage.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<MorphSessionReservation> reserveMorphSession({
    required String referenceImagePath,
    required int estimatedSeconds,
  }) async {
    final data = await functions.invokeMap(
      'morph-session',
      body: {
        'action': 'reserve',
        'reference_image_path': referenceImagePath,
        'estimated_seconds': estimatedSeconds,
      },
    );
    return MorphSessionReservation.fromJson(data);
  }

  Future<void> finalizeMorphSession({
    required String sessionId,
    required int elapsedSeconds,
  }) async {
    await functions.invokeMap(
      'morph-session',
      body: {
        'action': 'finalize',
        'session_id': sessionId,
        'elapsed_seconds': elapsedSeconds,
      },
    );
  }

  Future<void> refundMorphSession(String sessionId) async {
    await functions.invokeMap(
      'morph-session',
      body: {'action': 'refund', 'session_id': sessionId},
    );
  }

  Future<DecartClientToken> createDecartToken({
    required String sessionId,
    required String model,
  }) async {
    final data = await functions.invokeMap(
      'decart-token',
      body: {'session_id': sessionId, 'model': model},
    );
    return DecartClientToken.fromJson(data);
  }
}
