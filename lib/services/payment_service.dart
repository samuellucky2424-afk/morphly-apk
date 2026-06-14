import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app_config.dart';
import '../models/credit_package.dart';
import '../services/edge_function_client.dart';
import '../services/supabase_gateway.dart';

enum PaymentChannel {
  appStore,
  playStore,
  flutterwave,
  unavailable,
}

class PaymentResult {
  const PaymentResult({
    required this.channel,
    required this.message,
    this.pending = false,
  });

  final PaymentChannel channel;
  final String message;
  final bool pending;
}

class PaymentService {
  PaymentService({
    this.gateway = const SupabaseGateway(),
    this.functions = const EdgeFunctionClient(),
    InAppPurchase? inAppPurchase,
  }) : inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final SupabaseGateway gateway;
  final EdgeFunctionClient functions;
  final InAppPurchase inAppPurchase;

  PaymentChannel channelFor(CreditPackage package) {
    if (package.flutterwaveEnabled) {
      return PaymentChannel.flutterwave;
    }
    if (Platform.isAndroid && AppConfig.isOffStoreAndroid) {
      return PaymentChannel.unavailable;
    }
    if (Platform.isIOS && package.appleProductId != null) {
      return PaymentChannel.appStore;
    }
    if (Platform.isAndroid && package.googleProductId != null) {
      return PaymentChannel.playStore;
    }
    return PaymentChannel.unavailable;
  }

  Future<PaymentResult> buyPackage({
    required BuildContext context,
    required CreditPackage package,
  }) async {
    switch (channelFor(package)) {
      case PaymentChannel.appStore:
      case PaymentChannel.playStore:
        return _buyWithStore(package);
      case PaymentChannel.flutterwave:
        return _buyWithFlutterwave(context, package);
      case PaymentChannel.unavailable:
        return const PaymentResult(
          channel: PaymentChannel.unavailable,
          message: 'Purchases are not available for this package yet.',
        );
    }
  }

  Future<PaymentResult> _buyWithStore(CreditPackage package) async {
    final productId = Platform.isIOS
        ? package.appleProductId
        : Platform.isAndroid
            ? package.googleProductId
            : null;

    if (productId == null) {
      return const PaymentResult(
        channel: PaymentChannel.unavailable,
        message: 'Missing store product id.',
      );
    }

    final available = await inAppPurchase.isAvailable();
    if (!available) {
      return const PaymentResult(
        channel: PaymentChannel.unavailable,
        message: 'Store billing is not available on this device.',
      );
    }

    final products = await inAppPurchase.queryProductDetails({productId});
    if (products.productDetails.isEmpty) {
      return const PaymentResult(
        channel: PaymentChannel.unavailable,
        message: 'This credit package is not configured in the store.',
      );
    }

    final details = products.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: details);
    final started = await inAppPurchase.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true,
    );
    if (!started) {
      return const PaymentResult(
        channel: PaymentChannel.unavailable,
        message: 'Store purchase could not be started.',
      );
    }

    return PaymentResult(
      channel:
          Platform.isIOS ? PaymentChannel.appStore : PaymentChannel.playStore,
      message:
          'Purchase started. Credits will appear after store verification.',
      pending: true,
    );
  }

  Future<PaymentResult> verifyStorePurchase({
    required PurchaseDetails purchase,
    required CreditPackage package,
  }) async {
    await functions.invokeMap(
      'store-purchase-verify',
      body: {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'package_code': package.code,
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'verification_data': purchase.verificationData.serverVerificationData,
      },
    );

    if (purchase.pendingCompletePurchase) {
      await inAppPurchase.completePurchase(purchase);
    }

    return PaymentResult(
      channel:
          Platform.isIOS ? PaymentChannel.appStore : PaymentChannel.playStore,
      message: 'Credits added.',
    );
  }

  Future<PaymentResult> _buyWithFlutterwave(
    BuildContext context,
    CreditPackage package,
  ) async {
    final data = await functions.invokeMap(
      'payment-options',
      body: {
        'channel': 'flutterwave',
        'package_code': package.code,
      },
    );

    final publicKey = data['flutterwave_public_key'] as String?;
    if (publicKey == null || publicKey.isEmpty) {
      return const PaymentResult(
        channel: PaymentChannel.flutterwave,
        message: 'Flutterwave is not configured for this release channel.',
      );
    }

    final user = gateway.client.auth.currentUser;
    final email = user?.email ?? 'customer@morphly.local';
    final txRef = data['tx_ref'] as String?;
    if (txRef == null || txRef.isEmpty) {
      return const PaymentResult(
        channel: PaymentChannel.flutterwave,
        message: 'Payment reference could not be created.',
      );
    }
    final amount = (package.priceMinor / 100).toStringAsFixed(0);

    final customer = Customer(
      phoneNumber: user?.phone ?? '',
      email: email,
    );

    final flutterwave = Flutterwave(
      publicKey: publicKey,
      currency: package.currency,
      redirectUrl:
          data['redirect_url'] as String? ?? 'morphly://payment-callback',
      txRef: txRef,
      amount: amount,
      customer: customer,
      paymentOptions:
          data['payment_options'] as String? ?? 'card, banktransfer, ussd',
      customization: Customization(title: 'Morphly Credits'),
      isTestMode: data['test_mode'] as bool? ?? true,
    );

    if (!context.mounted) {
      return const PaymentResult(
        channel: PaymentChannel.flutterwave,
        message: 'Payment cancelled.',
      );
    }
    final response = await flutterwave.charge(context);
    if (response.success != true) {
      return const PaymentResult(
        channel: PaymentChannel.flutterwave,
        message: 'Payment was not completed.',
      );
    }
    final transactionId = response.transactionId;
    if (transactionId == null || transactionId.isEmpty) {
      return const PaymentResult(
        channel: PaymentChannel.flutterwave,
        message:
            'Payment submitted. Credits will appear after webhook verification.',
        pending: true,
      );
    }

    await functions.invokeMap(
      'flutterwave-webhook',
      body: {
        'manual_verify': true,
        'transaction_id': transactionId,
        'tx_ref': txRef,
        'package_code': package.code,
      },
    );

    return const PaymentResult(
      channel: PaymentChannel.flutterwave,
      message: 'Payment submitted. Credits will appear after verification.',
      pending: true,
    );
  }
}
