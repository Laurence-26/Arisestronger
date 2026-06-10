import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/brand_wordmark.dart';
import '../widgets/system_button.dart';

/// Email/password sign-in & sign-up with the Solo Leveling "System" look.
class AuthScreen extends StatefulWidget {
  final SupabaseService service;
  const AuthScreen({super.key, required this.service});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final email = _email.text.trim();
      final pass = _password.text;
      if (email.isEmpty || pass.length < 6) {
        throw 'Enter a valid email and a password of at least 6 characters.';
      }
      if (_isSignUp) {
        final name = _name.text.trim().isEmpty ? 'Hunter' : _name.text.trim();
        await widget.service
            .signUp(email: email, password: pass, displayName: name);
        // If email confirmation is on, there is no session yet.
        if (widget.service.currentUser == null && mounted) {
          setState(() => _info =
              'Account created. Check your email to confirm, then sign in.');
        }
      } else {
        await widget.service.signIn(email: email, password: pass);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.service.signInWithGoogle();
      // Browser opens; session arrives via authStateChanges in AuthGate.
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('◈ SYSTEM INTERFACE ◈',
                      textAlign: TextAlign.center,
                      style: monoStyle(
                          size: 11, color: AppColors.purple, spacing: 5)),
                  const SizedBox(height: 14),
                  const Center(child: BrandWordmark(size: 38)),
                  const SizedBox(height: 8),
                  Text(_isSignUp ? 'AWAKEN AS A HUNTER' : 'WELCOME BACK, HUNTER',
                      textAlign: TextAlign.center,
                      style: monoStyle(size: 12, spacing: 2)),
                  const SizedBox(height: 32),
                  if (_isSignUp) ...[
                    _field(_name, 'Hunter name', Icons.person_outline),
                    const SizedBox(height: 14),
                  ],
                  _field(_email, 'Email', Icons.alternate_email,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _field(_password, 'Password', Icons.lock_outline,
                      obscure: true),
                  const SizedBox(height: 14),
                  if (_error != null)
                    _banner(_error!, AppColors.red),
                  if (_info != null) _banner(_info!, AppColors.green),
                  const SizedBox(height: 8),
                  SystemButton(
                    label: _isSignUp ? '◈ ARISE ◈' : '◈ ENTER ◈',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR', style: monoStyle(size: 10, spacing: 2)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _GoogleButton(onPressed: _busy ? null : _google),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                              _info = null;
                            }),
                    child: Text(
                      _isSignUp
                          ? 'Already a Hunter? Sign in'
                          : 'New here? Create an account',
                      style: const TextStyle(color: AppColors.textDim),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: AppColors.textBright),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textDim, size: 20),
      ),
    );
  }

  Widget _banner(String msg, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(msg, style: TextStyle(color: color, fontSize: 13)),
      );
}

/// "Continue with Google" button styled to match the System theme.
class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.bg3,
          side: const BorderSide(color: AppColors.borderBright),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Text('G',
              style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
        label: const Text('Continue with Google',
            style: TextStyle(
                color: AppColors.textBright,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
      ),
    );
  }
}
