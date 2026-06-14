import 'package:flutter/material.dart';

import '../app_config.dart';
import '../repositories/auth_repository.dart';
import '../theme/morphly_tokens.dart';
import '../widgets/morphly_components.dart';
import 'camera_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = const AuthRepository();
  bool _creatingAccount = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!AppConfig.hasSupabase) {
      _showMessage('Add Supabase dart-defines to enable real login.');
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const CameraScreen()),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_creatingAccount) {
        await _auth.signUp(email: _email.text, password: _password.text);
        _showMessage(
            'Account created. Check your email if verification is enabled.');
      } else {
        await _auth.signIn(email: _email.text, password: _password.text);
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const CameraScreen()),
      );
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!AppConfig.hasSupabase) {
      _showMessage('Supabase is not configured yet.');
      return;
    }
    if (_email.text.trim().isEmpty) {
      _showMessage('Enter your email first.');
      return;
    }
    await _auth.resetPassword(_email.text);
    _showMessage('Password reset email sent.');
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MorphlySpacing.page),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: MorphlyCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Morphly',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: MorphlyColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _creatingAccount
                              ? 'Create your account'
                              : 'Welcome back',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: MorphlyColors.onSurfaceVariant,
                                  ),
                        ),
                        if (!AppConfig.hasSupabase) ...[
                          const SizedBox(height: 18),
                          _ConfigNotice(),
                        ],
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Enter a valid email.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              tooltip: 'Toggle password',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Use at least 8 characters.';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: GlowButton(
                            label:
                                _creatingAccount ? 'Create account' : 'Login',
                            loading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(
                                    () => _creatingAccount = !_creatingAccount,
                                  ),
                          child: Text(
                            _creatingAccount
                                ? 'Already have an account? Login'
                                : "Don't have an account? Create account",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MorphlyColors.primary.withValues(alpha: 0.09),
        borderRadius: const BorderRadius.all(MorphlyRadius.medium),
        border: Border.all(
          color: MorphlyColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: MorphlyColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo mode is active until SUPABASE_URL and SUPABASE_ANON_KEY are provided.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
