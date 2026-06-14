import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/morphly_tokens.dart';

class MeshBackground extends StatelessWidget {
  const MeshBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C0613),
            MorphlyColors.background,
            MorphlyColors.background,
            Color(0xFF041008),
          ],
          stops: [0, 0.32, 0.72, 1],
        ),
      ),
      child: child,
    );
  }
}

class FrostedTopBar extends StatelessWidget {
  const FrostedTopBar({
    required this.credits,
    required this.onMenu,
    required this.onCredits,
    this.leadingIcon = Icons.menu_rounded,
    this.leadingTooltip = 'Menu',
    super.key,
  });

  final int credits;
  final VoidCallback onMenu;
  final VoidCallback onCredits;
  final IconData leadingIcon;
  final String leadingTooltip;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(MorphlyRadius.xLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: MorphlyColors.card.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.all(MorphlyRadius.xLarge),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: MorphlyShadows.purpleGlow(0.12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              IconButton(
                onPressed: onMenu,
                icon: Icon(leadingIcon),
                color: MorphlyColors.primary,
                tooltip: leadingTooltip,
              ),
              const Spacer(),
              Text(
                'Morphly',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              CreditPill(credits: credits, onTap: onCredits),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class CreditPill extends StatelessWidget {
  const CreditPill({required this.credits, required this.onTap, super.key});

  final int credits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(MorphlyRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: MorphlyColors.surfaceContainerHigh.withValues(alpha: 0.65),
          borderRadius: const BorderRadius.all(MorphlyRadius.pill),
          border: Border.all(
            color: MorphlyColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$credits',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: MorphlyColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.bolt_rounded,
              color: Color(0xFFFFC72C),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class MorphlyCard extends StatelessWidget {
  const MorphlyCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(MorphlySpacing.md),
      decoration: BoxDecoration(
        color: MorphlyColors.card,
        borderRadius: const BorderRadius.all(MorphlyRadius.large),
        border: Border.all(color: MorphlyColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GlowButton extends StatelessWidget {
  const GlowButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? MorphlyColors.onSecondary : MorphlyColors.white;
    final decoration = filled
        ? BoxDecoration(
            color: MorphlyColors.secondary,
            borderRadius: const BorderRadius.all(MorphlyRadius.pill),
            boxShadow: MorphlyShadows.greenGlow(0.38),
          )
        : BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.all(MorphlyRadius.pill),
            border: Border.all(color: MorphlyColors.primary, width: 1.5),
          );

    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: InkWell(
        borderRadius: const BorderRadius.all(MorphlyRadius.pill),
        onTap: loading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: decoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: foreground),
              if (icon != null || loading) const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaptureButton extends StatelessWidget {
  const CaptureButton({
    required this.running,
    required this.onPressed,
    super.key,
  });

  final bool running;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: running ? MorphlyColors.danger : MorphlyColors.secondary,
          shape: BoxShape.circle,
          boxShadow: running
              ? [
                  BoxShadow(
                    color: MorphlyColors.danger.withValues(alpha: 0.38),
                    blurRadius: 28,
                    spreadRadius: -3,
                  ),
                ]
              : MorphlyShadows.greenGlow(0.55),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: running ? 28 : 46,
            height: running ? 28 : 46,
            decoration: BoxDecoration(
              border: Border.all(
                color: running ? Colors.white : MorphlyColors.onSecondary,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(running ? 6 : 999),
            ),
            child: running
                ? null
                : const Icon(
                    Icons.play_arrow_rounded,
                    color: MorphlyColors.onSecondary,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }
}
