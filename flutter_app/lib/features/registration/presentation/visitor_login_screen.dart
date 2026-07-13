import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/glass_theme.dart';
import 'visitor_registration_screen.dart';
import '../../appointments/presentation/request_appointment_screen.dart';

class VisitorLoginScreen extends StatefulWidget {
  const VisitorLoginScreen({super.key});

  @override
  State<VisitorLoginScreen> createState() => _VisitorLoginScreenState();
}

class _VisitorLoginScreenState extends State<VisitorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.101.199:8000/login'), // Backend URL
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': _emailController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // final token = data['access_token'];
        // TODO: Save token to local storage and navigate to Visitor Dashboard
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RequestAppointmentScreen()),
        );
      } else {
        setState(() {
          _errorMsg = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Failed to connect to server: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VisitorRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: GlassTheme.primaryViolet,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login to manage your appointments',
                          style: TextStyle(color: GlassTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent)),
                          ),
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: GlassTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Email / Username',
                            labelStyle: TextStyle(color: GlassTheme.textSecondary),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: GlassTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: GlassTheme.textSecondary),
                          ),
                          obscureText: true,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.primaryViolet,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(color: GlassTheme.textSecondary)),
                            TextButton(
                              onPressed: _navigateToRegister,
                              child: const Text('Register Now', style: TextStyle(color: GlassTheme.primaryViolet, fontWeight: FontWeight.bold)),
                            )
                          ],
                        )
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
