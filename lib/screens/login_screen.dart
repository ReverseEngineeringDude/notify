import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                  // Logo or Icon could go here
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
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
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                         Text(
                          "Sign in to continue managing your ward.",
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: authService.isLoading
                              ? null
                              : () async {
                                  final error = await authService.login(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                                  if (error != null) {
                                    setState(() {
                                      _errorMessage = error;
                                    });
                                  }
                                },
                          child: authService.isLoading
                              ? const SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("LOGIN TO DASHBOARD"),
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
                          TextButton.icon(
                            icon: const Icon(Icons.bar_chart_rounded),
                            label: const Text("View Public Statistics"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PublicStatsScreen()),
                              );
                            },
                          ),
                          const Divider(height: 24),
                          TextButton(
                            onPressed: () async {
                              // Create Test Users
                              await authService.createMockUser(
                                email: "admin@test.com",
                                password: "password123",
                                role: UserRole.superAdmin,
                              );
                              await authService.createMockUser(
                                email: "ward1@test.com",
                                password: "password123",
                                role: UserRole.wardAdmin,
                                wardId: "Ward-01",
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Test users created! Try admin@test.com / ward1@test.com")),
                                );
                              }
                            },
                            child: const Text("Seed Test Database (Dev Only)", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
