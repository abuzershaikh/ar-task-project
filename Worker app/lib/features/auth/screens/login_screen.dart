import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../navigation/screens/main_nav_screen.dart';

/// Login / Register screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'worker1@example.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  final _nameController = TextEditingController(text: 'Worker User');
  bool _isRegistering = false;

  void _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    bool success = false;
    if (_isRegistering) {
      success = await authProvider.register(email, password, name);
    } else {
      success = await authProvider.login(email, password);
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon / Logo Badge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Task Reward',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete Tasks • Earn Real Money',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.accentColor),
                  ),
                  const SizedBox(height: 36),

                  // Login Form Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isRegistering ? 'Create Worker Account' : 'Worker Login',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),

                          if (_isRegistering) ...[
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (authProvider.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.dangerColor),
                              ),
                              child: Text(
                                authProvider.errorMessage!,
                                style: const TextStyle(color: AppTheme.dangerColor, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _submit,
                              child: authProvider.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(_isRegistering ? 'Sign Up' : 'Sign In'),
                            ),
                          ),

                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isRegistering = !_isRegistering;
                              });
                            },
                            child: Text(
                              _isRegistering
                                  ? 'Already have an account? Sign In'
                                  : "Don't have an account? Sign Up",
                              style: const TextStyle(color: AppTheme.primaryColor),
                            ),
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
