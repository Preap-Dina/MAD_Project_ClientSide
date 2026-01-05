import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ApiService api = ApiService();
  bool logged = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // naive: try to call logout-protected me endpoint is not implemented, skip
    setState(() => logged = false);
  }

  Future<void> _logout() async {
    await api.logout();
    setState(() => logged = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            logged
                ? Column(
                    children: [
                      Text('Logged in'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _logout,
                        child: const Text('Logout'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(index: 3),
    );
  }
}
