import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _entryController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
      );

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(loginSuccessMessage)));
      widget.onLoginSuccess();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(_errorMessage(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset is managed by your administrator.'),
      ),
    );
  }

  String _errorMessage(Object error) {
    final String message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return networkErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.primary, Color(0xFF0D47A1)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -40,
              top: 80,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: 120,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                      Icons.warehouse,
                                      size: 56,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    inventoryProName,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Manage your stock with ease',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 32),
                                  CustomTextField(
                                    controller: _emailController,
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (String? value) {
                                      final String trimmed =
                                          value?.trim() ?? '';
                                      if (trimmed.isEmpty) {
                                        return 'Email is required.';
                                      }
                                      if (!trimmed.contains('@')) {
                                        return 'Enter a valid email address.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    validator: (String? value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Password is required.';
                                      }
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              if (!mounted) {
                                                return;
                                              }

                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _showForgotPasswordNotice,
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    label: 'Login',
                                    onPressed: _isLoading ? null : _login,
                                    isLoading: _isLoading,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
