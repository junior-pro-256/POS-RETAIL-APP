import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 2 - Login (with a simple sign-up mode)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true;
  bool _remember = true;
  bool _signup = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _submit() {
    final state = context.read<AppState>();
    final id = _id.text.trim();
    final pw = _pw.text;
    if (id.isEmpty || pw.isEmpty || (_signup && _name.text.trim().isEmpty)) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (_signup) {
      if (pw.length < 8) {
        setState(() => _error = 'Password must be at least 8 characters.');
        return;
      }
      state.signUp(_name.text.trim(), id, pw);
      Navigator.pushReplacementNamed(context, Routes.home);
      return;
    }
    if (state.login(id, pw, remember: _remember)) {
      Navigator.pushReplacementNamed(context, Routes.home);
    } else {
      setState(() => _error = 'Incorrect email/phone or password.');
    }
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: simpleAppBar('', back: Navigator.canPop(context)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_signup ? 'Create account' : 'Login',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_signup ? 'Set up your business account' : 'Sign in to your account',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              if (_signup) ...[
                TextField(controller: _name, decoration: _dec('Full name', Icons.person_outline)),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _id,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email or Phone', Icons.mail_outline),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pw,
                obscureText: _hide,
                decoration: _dec(
                  'Password',
                  Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              if (!_signup)
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                    ),
                    const Text('Remember me', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => toast(context,
                          'Password reset needs a backend. Use Settings > Security once logged in.'),
                      child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                )
              else
                const SizedBox(height: 14),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              PrimaryButton(label: _signup ? 'Sign Up' : 'Login', onPressed: _submit),
              if (!_signup) ...[
                const SizedBox(height: 10),
                Text('Demo: owner@business.com / password123',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ]),
              const SizedBox(height: 18),
              _social(Icons.g_mobiledata, 'Continue with Google'),
              const SizedBox(height: 10),
              _social(Icons.apple, 'Continue with Apple'),
              const SizedBox(height: 22),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_signup ? 'Already have an account? ' : "Don't have an account? ",
                        style: const TextStyle(fontSize: 13)),
                    GestureDetector(
                      onTap: () => setState(() {
                        _signup = !_signup;
                        _error = null;
                      }),
                      child: Text(_signup ? 'Login' : 'Sign Up',
                          style: TextStyle(
                              fontSize: 13, color: primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _social(IconData icon, String label) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () => toast(context,
            '$label needs OAuth set up (google_sign_in / sign_in_with_apple).'),
        icon: Icon(icon, size: 24, color: Colors.black87),
        label: Text(label, style: const TextStyle(color: Colors.black87)),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
