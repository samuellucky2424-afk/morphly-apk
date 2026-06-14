import 'package:intl/intl.dart';

class CreditPackage {
  const CreditPackage({
    required this.id,
    required this.code,
    required this.credits,
    required this.priceMinor,
    required this.currency,
    required this.isPopular,
    this.appleProductId,
    this.googleProductId,
    this.flutterwaveEnabled = false,
  });

  final String id;
  final String code;
  final int credits;
  final int priceMinor;
  final String currency;
  final bool isPopular;
  final String? appleProductId;
  final String? googleProductId;
  final bool flutterwaveEnabled;

  factory CreditPackage.fromJson(Map<String, dynamic> json) {
    return CreditPackage(
      id: json['id'] as String,
      code: json['code'] as String,
      credits: json['credits'] as int,
      priceMinor: json['price_minor'] as int,
      currency: json['currency'] as String? ?? 'NGN',
      isPopular: json['is_popular'] as bool? ?? false,
      appleProductId: json['apple_product_id'] as String?,
      googleProductId: json['google_product_id'] as String?,
      flutterwaveEnabled: json['flutterwave_enabled'] as bool? ?? false,
    );
  }

  String get displayPrice {
    final formatter = NumberFormat.currency(
      locale: currency == 'NGN' ? 'en_NG' : 'en_US',
      symbol: currency == 'NGN' ? '₦' : '$currency ',
      decimalDigits: 0,
    );
    return formatter.format(priceMinor / 100);
  }

  String? productIdForStore(String store) {
    if (store == 'app_store') return appleProductId;
    if (store == 'play_store') return googleProductId;
    return null;
  }
}
