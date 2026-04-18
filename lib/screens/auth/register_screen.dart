import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agreedTerms = false;
  bool _loading = false;
  String? _error;
  bool _showConfirmation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreedTerms) {
      setState(() => _error = 'Please accept terms & conditions');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await AuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );
      
      if (response.session != null) {
        await ref.read(userProfileProvider.notifier).loadProfile();
        if (mounted) context.go('/');
      } else {
        setState(() {
          _loading = false;
          _showConfirmation = true;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = await AuthService.signInWithGoogle();
      if (!success) {
        throw Exception('Google sign-in was cancelled or failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Google login failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _loading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait... creating your account')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Title(
        title: 'Register | Blissfruitz',
        color: Colors.green,
        child: Stack(
          children: [
          // Background decorations matching login
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Join Blissfruitz',
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
                    ),
                    const SizedBox(height: 32),

                    GlassCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showConfirmation) ...[
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15), width: 1.5),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.primary, size: 48),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Verification Required',
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'A verification link has been sent to:',
                                      style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppTheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _emailController.text,
                                      style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Please click the link in your inbox to verify your account. If you don\'t see it, check your spam folder.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, height: 1.5),
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          context.go('/login');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text('Go to Sign In'),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _showConfirmation = false);
                                      },
                                      child: const Text('Try another email', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            if (_error != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
                              ),
                              const SizedBox(height: 20),
                            ],

                            _buildLabel('Full Name'),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Email Address'),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Password'),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure1,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Confirm Password'),
                            TextField(
                              controller: _confirmController,
                              obscureText: _obscure2,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedTerms,
                                  onChanged: (v) => setState(() => _agreedTerms = v ?? false),
                                  activeColor: AppTheme.primary,
                                ),
                                Expanded(
                                  child: Text('I agree to the Terms & Privacy Policy', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : () {
                                  HapticFeedback.lightImpact();
                                  _register();
                                },
                                child: _loading 
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Text('Create Account'),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Row(
                              children: [
                                Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR CONTINUE WITH', 
                                    style: GoogleFonts.outfit(
                                      fontSize: 10, 
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6), 
                                      fontWeight: FontWeight.w800, 
                                      letterSpacing: 1.5
                                    )
                                  ),
                                ),
                                Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08))),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _loading ? null : () {
                                  HapticFeedback.lightImpact();
                                  _signInWithGoogle();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                ),
                                child: _loading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/google_logo.png',
                                          height: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Continue with Google',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],

                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/login');
                          },
                          child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 9, 
          fontWeight: FontWeight.w800, 
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
