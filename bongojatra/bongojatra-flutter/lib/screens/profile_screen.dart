import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'passenger_details_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await _authService.getName() ?? 'Traveler';
    final email = await _authService.getEmail() ?? 'traveler@example.com';
    if (mounted) {
      setState(() {
        _name = name;
        _email = email;
      });
    }
  }

  void _signOut() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            color: AppTheme.primary,
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 40,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'T',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $_name',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.person_rounded,
                    label: 'Passenger Details',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PassengerDetailsScreen())),
                  ),
                  _buildMenuItem(
                    icon: Icons.payment_rounded,
                    label: 'Payment Methods',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Payment Methods'),
                          content: const Text(
                              'Saved cards feature is not available in this prototype.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'))
                          ],
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.confirmation_number_rounded,
                    label: 'My Bookings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Go to Tickets tab to view bookings')));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Customer Service',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Customer Service'),
                          content: const Text(
                              'This is a university prototype. No real customer service is available.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'))
                          ],
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.star_rounded,
                    label: 'Give Feedback',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Thank you for your feedback!')));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    textColor: AppTheme.secondary,
                    iconColor: AppTheme.secondary,
                    onTap: _signOut,
                    showArrow: false,
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const Center(
              child: Text(
                'Version 1.0.0 — BongoJatra Prototype',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = AppTheme.textDark,
    Color iconColor = Colors.grey,
    bool showArrow = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          trailing: showArrow
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null,
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        ),
        const Divider(height: 1, indent: 64),
      ],
    );
  }
}
