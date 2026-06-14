import 'dart:async';
import 'dart:io';

import 'package:decart_realtime_bridge/decart_realtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_config.dart';
import '../models/user_settings.dart';
import '../repositories/auth_repository.dart';
import '../repositories/credits_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/reference_image_service.dart';
import '../theme/morphly_tokens.dart';
import '../widgets/morphly_components.dart';
import 'login_screen.dart';
import 'purchase_credits_screen.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _creditsRepository = const CreditsRepository();
  final _settingsRepository = const SettingsRepository();
  final _imageService = const ReferenceImageService();
  final _picker = ImagePicker();

  StreamSubscription<DecartBridgeEvent>? _bridgeSubscription;
  UserSettings _settings = UserSettings.defaults;
  String? _referenceImagePath;
  String? _sessionId;
  int _credits = 0;
  int _elapsedSeconds = 0;
  bool _loading = true;
  bool _starting = false;
  bool _running = false;
  bool _controlsVisible = true;
  String _status = 'Upload a reference image and tap Start';

  bool get _sessionActive => _starting || _running;

  @override
  void initState() {
    super.initState();
    _bridgeSubscription = DecartRealtimeBridge.events.listen(_onBridgeEvent);
    unawaited(_load());
  }

  @override
  void dispose() {
    _bridgeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final settings = await _settingsRepository.fetch();
      final credits =
          AppConfig.hasSupabase ? await _creditsRepository.fetchBalance() : 120;
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _credits = credits;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(error.toString());
    }
  }

  void _onBridgeEvent(DecartBridgeEvent event) {
    if (!mounted) return;
    final sessionEnded = event.state == DecartConnectionState.failed ||
        event.state == DecartConnectionState.stopped ||
        event.state == DecartConnectionState.idle;
    setState(() {
      _elapsedSeconds = event.elapsedSeconds;
      _running = event.state == DecartConnectionState.connected;
      _starting = event.state == DecartConnectionState.starting;
      if (sessionEnded) _controlsVisible = true;
      _status = event.message ?? event.state.name;
    });
    if (event.state == DecartConnectionState.failed && _sessionId != null) {
      unawaited(_creditsRepository.refundMorphSession(_sessionId!));
    }
  }

  Future<void> _pickReferenceImage() async {
    final result = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1600,
    );
    if (result == null) return;

    final image = File(result.path);
    setState(() {
      _referenceImagePath = result.path;
      _status = 'Reference selected';
    });

    if (!AppConfig.hasSupabase) return;

    try {
      final remotePath = await _imageService.upload(image);
      if (!mounted) return;
      setState(() {
        _referenceImagePath = remotePath;
        _status = 'Reference uploaded';
      });
    } catch (error) {
      _showMessage('Image upload failed: $error');
    }
  }

  Future<void> _toggleSession() async {
    if (_running || _starting) {
      await _stopSession();
    } else {
      await _startSession();
    }
  }

  Future<void> _startSession() async {
    if (_referenceImagePath == null) {
      _showMessage('Upload a reference image first.');
      return;
    }

    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      _showMessage('Camera permission is required for live morphing.');
      return;
    }

    if (_credits <= 0) {
      _showMessage('Buy credits before starting a morph session.');
      return;
    }

    setState(() {
      _starting = true;
      _controlsVisible = false;
      _elapsedSeconds = 0;
      _status = 'Preparing live morph';
    });

    String? reservedSessionId;
    try {
      if (AppConfig.hasSupabase) {
        final reservation = await _creditsRepository.reserveMorphSession(
          referenceImagePath: _referenceImagePath!,
          estimatedSeconds: 30,
        );
        reservedSessionId = reservation.sessionId;
        final token = await _creditsRepository.createDecartToken(
          sessionId: reservation.sessionId,
          model: AppConfig.decartModel,
        );
        await DecartRealtimeBridge.startSession(
          DecartSessionConfig(
            sessionId: reservation.sessionId,
            clientToken: token.apiKey,
            model: token.model,
            referenceImagePath: _referenceImagePath!,
            prompt: 'Morph the live camera feed toward the selected reference.',
            quality: _settings.cameraQuality.name,
          ),
        );
        setState(() {
          _sessionId = reservation.sessionId;
          _credits = reservation.balance;
        });
      } else {
        await DecartRealtimeBridge.startSession(
          DecartSessionConfig(
            sessionId: 'demo-session',
            clientToken: 'demo-token',
            model: AppConfig.decartModel,
            referenceImagePath: _referenceImagePath!,
            prompt: 'Demo Morphly realtime session',
            quality: _settings.cameraQuality.name,
          ),
        );
        setState(() => _sessionId = 'demo-session');
      }
    } catch (error) {
      if (reservedSessionId != null) {
        await _creditsRepository.refundMorphSession(reservedSessionId);
      }
      if (!mounted) return;
      setState(() {
        _starting = false;
        _running = false;
        _controlsVisible = true;
        _status = 'Start failed';
      });
      _showMessage(error.toString());
    }
  }

  Future<void> _stopSession() async {
    final sessionId = _sessionId;
    final elapsed = _elapsedSeconds;
    setState(() {
      _starting = false;
      _running = false;
      _controlsVisible = true;
      _status = 'Stopping session';
    });
    await DecartRealtimeBridge.stopSession();

    if (AppConfig.hasSupabase && sessionId != null) {
      await _creditsRepository.finalizeMorphSession(
        sessionId: sessionId,
        elapsedSeconds: elapsed,
      );
      final balance = await _creditsRepository.fetchBalance();
      if (!mounted) return;
      setState(() => _credits = balance);
    }

    if (!mounted) return;
    setState(() {
      _sessionId = null;
      _elapsedSeconds = 0;
      _status = 'Session stopped';
    });
  }

  Future<void> _openPurchases() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PurchaseCreditsScreen()),
    );
    await _load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    final settings = await _settingsRepository.fetch();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _logout() async {
    if (AppConfig.hasSupabase) await const AuthRepository().signOut();
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MorphlyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: MorphlyRadius.xLarge),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetAction(
                  icon: Icons.bolt_rounded,
                  label: 'Purchase Credits',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_openPurchases());
                  },
                ),
                _SheetAction(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_openSettings());
                  },
                ),
                _SheetAction(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  danger: true,
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_logout());
                  },
                ),
              ],
            ),
          ),
        );
      },
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _sessionActive
            ? () => setState(() => _controlsVisible = !_controlsVisible)
            : null,
        child: MeshBackground(
          child: _sessionActive
              ? _buildFullscreenSession(context)
              : _buildSetupMode(context),
        ),
      ),
    );
  }

  Widget _buildSetupMode(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            FrostedTopBar(
              credits: _credits,
              onMenu: _showMenu,
              onCredits: _openPurchases,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _CameraCanvas(
                loading: _loading,
                status: _status,
                running: _running,
                starting: _starting,
                elapsedSeconds: _elapsedSeconds,
                referenceReady: _referenceImagePath != null,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 18, 0, 20 + bottomPadding),
              child: Row(
                children: [
                  Expanded(
                    child: GlowButton(
                      label: _referenceImagePath == null
                          ? 'Upload Image'
                          : 'Change Image',
                      icon: Icons.add_photo_alternate_outlined,
                      filled: false,
                      onPressed: _pickReferenceImage,
                    ),
                  ),
                  const SizedBox(width: 18),
                  CaptureButton(
                    running: _running || _starting,
                    onPressed: _toggleSession,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenSession(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: _CameraCanvas(
            loading: _loading,
            status: _status,
            running: _running,
            starting: _starting,
            elapsedSeconds: _elapsedSeconds,
            fullscreen: true,
            referenceReady: _referenceImagePath != null,
          ),
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _controlsVisible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    right: 20,
                    top: topPadding + 16,
                    child: FrostedTopBar(
                      credits: _credits,
                      onMenu: _showMenu,
                      onCredits: _openPurchases,
                      leadingIcon: Icons.close_fullscreen_rounded,
                      leadingTooltip: 'Session menu',
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomPadding + 24,
                    child: Center(
                      child: CaptureButton(
                        running: true,
                        onPressed: _toggleSession,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraCanvas extends StatelessWidget {
  const _CameraCanvas({
    required this.loading,
    required this.status,
    required this.running,
    required this.starting,
    required this.elapsedSeconds,
    required this.referenceReady,
    this.fullscreen = false,
  });

  final bool loading;
  final String status;
  final bool running;
  final bool starting;
  final int elapsedSeconds;
  final bool referenceReady;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final borderRadius = fullscreen
        ? BorderRadius.zero
        : const BorderRadius.all(MorphlyRadius.xLarge);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: borderRadius,
        border: fullscreen
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: RadialGradient(
                center: const Alignment(0.1, -0.25),
                radius: fullscreen ? 1.05 : 0.86,
                colors: [
                  MorphlyColors.primary.withValues(alpha: 0.20),
                  MorphlyColors.secondary.withValues(alpha: 0.08),
                  Colors.black,
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    running || starting
                        ? Icons.auto_awesome_rounded
                        : referenceReady
                            ? Icons.check_circle_outline_rounded
                            : Icons.camera_alt_outlined,
                    color: running || starting
                        ? MorphlyColors.secondary
                        : referenceReady
                            ? MorphlyColors.secondary
                            : MorphlyColors.primary,
                    size: fullscreen ? 54 : 42,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loading ? 'Loading Morphly' : status,
                    textAlign: TextAlign.center,
                    style: (fullscreen
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.titleMedium)
                        ?.copyWith(
                          color: MorphlyColors.onSurface,
                        ),
                  ),
                  if (running || starting) ...[
                    const SizedBox(height: 8),
                    Text(
                      running ? '${elapsedSeconds}s live' : 'Connecting',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MorphlyColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? MorphlyColors.danger : MorphlyColors.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
