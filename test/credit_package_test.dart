import 'package:flutter_test/flutter_test.dart';
import 'package:morphly/models/credit_package.dart';

void main() {
  test('CreditPackage parses backend rows and formats naira price', () {
    final package = CreditPackage.fromJson(const {
      'id': 'package-id',
      'code': 'credits_120',
      'credits': 120,
      'price_minor': 200000,
      'currency': 'NGN',
      'is_popular': true,
      'flutterwave_enabled': true,
    });

    expect(package.code, 'credits_120');
    expect(package.credits, 120);
    expect(package.isPopular, isTrue);
    expect(package.flutterwaveEnabled, isTrue);
    expect(package.displayPrice, contains('2,000'));
  });
}
