import 'dart:async';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../models/user_settings.dart';
import '../repositories/auth_repository.dart';
import '../repositories/credits_repository.dart';
import '../repositories/settings_repository.dart';
import '../theme/morphly_tokens.dart';
import '../widgets/morphly_components.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepository = const SettingsRepository();
  final _creditsRepository = const CreditsRepository();
  UserSettings _settings = UserSettings.defaults;
  int _credits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _settingsRepository.fetch(),
        _creditsRepository.fetchBalance(),
      ]);
      if (!mounted) return;
      setState(() {
        _settings = results[0] as UserSettings;
        _credits = results[1] as int;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _save(UserSettings settings) async {
    setState(() => _settings = settings);
    try {
      await _settingsRepository.save(settings);
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _logout() async {
    if (AppConfig.hasSupabase) await const AuthRepository().signOut();
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showMessage(String message) {
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
                Text('Settings',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        MorphlyCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preferences',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: MorphlyColors.primary),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Camera Quality',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 10),
                              _QualitySelector(
                                value: _settings.cameraQuality,
                                onChanged: (quality) => _save(
                                  _settings.copyWith(cameraQuality: quality),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Divider(color: MorphlyColors.border),
                              _SettingsSwitch(
                                title: 'Dark Mode',
                                subtitle:
                                    'Optimized for low light environments',
                                value: _settings.darkMode,
                                onChanged: (value) => _save(
                                  _settings.copyWith(darkMode: value),
                                ),
                              ),
                              const Divider(color: MorphlyColors.border),
                              _SettingsSwitch(
                                title: 'Notifications',
                                subtitle: 'Get alerts for complete morphs',
                                value: _settings.notifications,
                                onChanged: (value) => _save(
                                  _settings.copyWith(notifications: value),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        MorphlyCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: MorphlyColors.primary),
                              ),
                              const SizedBox(height: 14),
                              _AccountRow(
                                icon: Icons.workspace_premium_outlined,
                                title: 'Pro Subscription',
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MorphlyColors.secondary.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      MorphlyRadius.small,
                                    ),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: MorphlyColors.secondary),
                                  ),
                                ),
                              ),
                              const Divider(color: MorphlyColors.border),
                              const _AccountRow(
                                icon: Icons.shield_outlined,
                                title: 'Privacy Policy',
                                trailing: Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: TextButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                            style: TextButton.styleFrom(
                              foregroundColor: MorphlyColors.danger,
                              textStyle: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({required this.value, required this.onChanged});

  final CameraQuality value;
  final ValueChanged<CameraQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MorphlyColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(MorphlyRadius.medium),
        border: Border.all(color: MorphlyColors.border),
      ),
      child: Row(
        children: CameraQuality.values.map((quality) {
          final selected = quality == value;
          return Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(MorphlyRadius.small),
              onTap: () => onChanged(quality),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selected ? MorphlyColors.secondary : Colors.transparent,
                  borderRadius: const BorderRadius.all(MorphlyRadius.small),
                  boxShadow: selected ? MorphlyShadows.greenGlow(0.28) : null,
                ),
                child: Text(
                  quality.name[0].toUpperCase() + quality.name.substring(1),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? MorphlyColors.onSecondary
                            : MorphlyColors.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MorphlyColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: MorphlyColors.secondary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: MorphlyColors.primary),
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      trailing: trailing,
    );
  }
}
