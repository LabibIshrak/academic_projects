import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({super.key});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _nidController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final name = await _authService.getName();
    final email = await _authService.getEmail();

    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('pd_name') ?? name ?? '';
        _emailController.text = email ?? '';
        _phoneController.text = prefs.getString('pd_phone') ?? '';
        _dobController.text = prefs.getString('pd_dob') ?? '';
        _nidController.text = prefs.getString('pd_nid') ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pd_name', _nameController.text);
    await prefs.setString('pd_phone', _phoneController.text);
    await prefs.setString('pd_dob', _dobController.text);
    await prefs.setString('pd_nid', _nidController.text);

    // Also update auth service name if changed
    await _authService.saveName(_nameController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details saved successfully')));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      fillColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Phone Number', hintText: '01XXXXXXXXX'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                        labelText: 'Date of Birth', hintText: 'DD/MM/YYYY'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'National ID',
                        hintText: '10 or 17 digit NID'),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveDetails,
                      child: const Text('Save Details'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
