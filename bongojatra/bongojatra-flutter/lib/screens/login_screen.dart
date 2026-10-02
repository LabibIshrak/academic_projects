import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  int _step = 0; // 0 = landing, 1 = email, 2 = password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onGoogleSignInTap() {
    setState(() => _step = 1);
    Future.delayed(const Duration(milliseconds: 300), () {
      _emailFocus.requestFocus();
    });
  }

  void _onEmailNext() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid email address')));
      return;
    }
    setState(() => _step = 2);
    Future.delayed(const Duration(milliseconds: 300), () {
      _passwordFocus.requestFocus();
    });
  }

  void _onBackToEmail() {
    setState(() => _step = 1);
  }

  Future<void> _handleSignIn() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) email = 'test@example.com';

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      String name = email.split('@')[0].replaceAll(RegExp(r'[._-]'), ' ');
      name = name.isEmpty
          ? 'Traveler'
          : name.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');

      String token = base64Encode(utf8.encode(email));
      try {
        final response =
            await ApiService().loginWithGoogle(email, name, 'demo-id-token');
        token = response['token'] ?? token;
        name = response['name'] ?? name;
        email = response['email'] ?? email;
      } catch (_) {
        // Demo mode — local login if backend unavailable
      }
      await authService.saveToken(token);
      await authService.saveName(name);
      await authService.saveEmail(email);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _step == 0
              ? _buildLandingStep()
              : _step == 1
                  ? _buildEmailStep()
                  : _buildPasswordStep(),
        ),
      ),
    );
  }

  // ─── Step 0: Landing ───
  Widget _buildLandingStep() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              const Text(
                'BongoJatra',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 4, bottom: 14),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideX(),
          const SizedBox(height: 60),
          const Text(
            'Welcome',
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 200.ms).slideY(),
          const SizedBox(height: 8),
          const Text(
            'Your journey across Bangladesh\nstarts here.',
            style: TextStyle(fontSize: 18, color: Colors.grey, height: 1.5),
          ).animate().fadeIn(delay: 300.ms).slideY(),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _onGoogleSignInTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textDark,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Text(
                'G',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              label: const Text(
                'Sign in with Google',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'By continuing you agree to our Terms of Service',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  // ─── Step 1: Email ───
  Widget _buildEmailStep() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _step = 0),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'G',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'oogle',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Sign in',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your Google Account',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email or phone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _onEmailNext(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Not your computer? Use a Private browsing window to sign in.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Account creation is simulated in this prototype.')));
                },
                child: const Text('Create account',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: _onEmailNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Password ───
  Widget _buildPasswordStep() {
    final email = _emailController.text.trim();
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackToEmail,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'G',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'oogle',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(email, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Enter your password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onSubmitted: (_) => _handleSignIn(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: !_obscurePassword,
                onChanged: (v) => setState(() => _obscurePassword = !(v ?? false)),
                activeColor: AppTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Text('Show password', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Password recovery is simulated.')));
                },
                child: const Text('Forgot password?',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
