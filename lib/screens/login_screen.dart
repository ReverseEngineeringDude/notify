import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons; // Minimal material for specific colors/icons if needed, but aiming for Cupertino
import 'package:provider/provider.dart';
import '../../services/haptic_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'public/public_stats_screen.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Using ModernScaffold which now wraps CupertinoPageScaffold
    return ModernScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedEntry(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Welcome Back",
                          style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                         Text(
                          "Sign in to continue managing your ward.",
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: CupertinoColors.systemGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        CupertinoTextField(
                          controller: _emailController,
                          placeholder: 'Email Address',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(CupertinoIcons.mail, color: CupertinoColors.systemGrey),
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CupertinoColors.systemGrey4),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        CupertinoTextField(
                          controller: _passwordController,
                          placeholder: 'Password',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(CupertinoIcons.lock, color: CupertinoColors.systemGrey),
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CupertinoColors.systemGrey4),
                          ),
                          obscureText: _obscurePassword,
                          suffix: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(
                              _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash, 
                              color: CupertinoColors.systemGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.destructiveRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: CupertinoColors.destructiveRed.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.destructiveRed, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: CupertinoColors.destructiveRed),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        CupertinoButton.filled(
                          child: authService.isLoading
                              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                              : const Text("Login to Dashboard"),
                          onPressed: authService.isLoading
                              ? null
                              : () async {
                                  HapticService.mediumImpact();
                                  final error = await authService.login(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                                  if (error != null) {
                                    HapticService.error();
                                    setState(() {
                                      _errorMessage = error;
                                    });
                                  } else {
                                    HapticService.success();
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedEntry(
                    delay: const Duration(milliseconds: 200),
                    child: GlassCard(
                      blur: 5,
                      opacity: 0.4,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Column(
                        children: [
                          CupertinoButton(
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.chart_bar_alt_fill),
                                SizedBox(width: 8),
                                Text("View Public Statistics"),
                              ],
                            ),
                            onPressed: () {
                              HapticService.selectionClick();
                              Navigator.push(
                                context,
                                CupertinoPageRoute(builder: (_) => const PublicStatsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
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
}
