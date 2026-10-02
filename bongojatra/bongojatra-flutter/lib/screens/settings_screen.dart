import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _signOut() async {
    final authService = AuthService();
    await authService.logout();
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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            activeThumbColor: AppTheme.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Language'),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('English', style: TextStyle(color: Colors.grey)),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showTextDialog('Privacy Policy',
                'This is a prototype application. No personal data is stored persistently.'),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showTextDialog('Terms of Service',
                'By using this prototype, you agree that it is for demonstration purposes only.'),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Sign Out',
                style: TextStyle(color: AppTheme.secondary)),
            onTap: _signOut,
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Version: 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
