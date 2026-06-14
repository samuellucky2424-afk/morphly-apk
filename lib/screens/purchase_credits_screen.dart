import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/credit_package.dart';
import '../repositories/credits_repository.dart';
import '../services/payment_service.dart';
import '../theme/morphly_tokens.dart';
import '../widgets/morphly_components.dart';

class PurchaseCreditsScreen extends StatefulWidget {
  const PurchaseCreditsScreen({super.key});

  @override
  State<PurchaseCreditsScreen> createState() => _PurchaseCreditsScreenState();
}

class _PurchaseCreditsScreenState extends State<PurchaseCreditsScreen> {
  final _creditsRepository = const CreditsRepository();
  final _paymentService = PaymentService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  List<CreditPackage> _packages = const [];
  int _credits = 0;
  bool _loading = true;
  String? _busyPackageCode;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _paymentService.inAppPurchase.purchaseStream.listen(
      _handleStorePurchases,
      onError: (Object error) => _showMessage(error.toString()),
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _creditsRepository.fetchPackages(),
        _creditsRepository.fetchBalance(),
      ]);
      if (!mounted) return;
      setState(() {
        _packages = results[0] as List<CreditPackage>;
        _credits = results[1] as int;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _buy(CreditPackage package) async {
    setState(() => _busyPackageCode = package.code);
    try {
      final result = await _paymentService.buyPackage(
        context: context,
        package: package,
      );
      _showMessage(result.message);
      if (!result.pending) await _load();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busyPackageCode = null);
    }
  }

  Future<void> _handleStorePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.error) {
        _showMessage(purchase.error?.message ?? 'Purchase failed.');
        continue;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      CreditPackage? package;
      for (final item in _packages) {
        if (item.appleProductId == purchase.productID ||
            item.googleProductId == purchase.productID) {
          package = item;
          break;
        }
      }

      if (package == null) continue;

      try {
        final result = await _paymentService.verifyStorePurchase(
          purchase: purchase,
          package: package,
        );
        _showMessage(result.message);
        await _load();
      } catch (error) {
        _showMessage(error.toString());
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FrostedTopBar(
                  credits: _credits,
                  onMenu: () => Navigator.pop(context),
                  onCredits: () {},
                  leadingIcon: Icons.arrow_back_rounded,
                  leadingTooltip: 'Back',
                ),
                const SizedBox(height: 34),
                Text(
                  'Purchase Credits',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a package',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: MorphlyColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          itemCount: _packages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final package = _packages[index];
                            return _CreditPackageTile(
                              package: package,
                              busy: _busyPackageCode == package.code,
                              onBuy: () => _buy(package),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditPackageTile extends StatelessWidget {
  const _CreditPackageTile({
    required this.package,
    required this.busy,
    required this.onBuy,
  });

  final CreditPackage package;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MorphlyColors.card,
        borderRadius: const BorderRadius.all(MorphlyRadius.large),
        border: Border.all(
          color:
              package.isPopular ? MorphlyColors.primary : MorphlyColors.border,
          width: package.isPopular ? 1.5 : 1,
        ),
        boxShadow: package.isPopular ? MorphlyShadows.purpleGlow(0.16) : null,
      ),
      child: Stack(
        children: [
          if (package.isPopular)
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: MorphlyColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: MorphlyRadius.large,
                    topRight: MorphlyRadius.large,
                  ),
                ),
                child: Text(
                  'POPULAR',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: MorphlyColors.onPrimaryContainer,
                      ),
                ),
              ),
            ),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: MorphlyColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${package.credits} Credits',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.displayPrice,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: MorphlyColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              GlowButton(
                label: 'Buy',
                loading: busy,
                filled: package.isPopular,
                onPressed: busy ? null : onBuy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
