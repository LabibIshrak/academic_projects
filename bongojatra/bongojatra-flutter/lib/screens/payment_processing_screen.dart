import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'ticket_screen.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final String optionId;
  final String seatId;
  final String paymentMethod;

  final String? classType;
  final String? coachId;
  final String? journeyDate;

  const PaymentProcessingScreen(
      {super.key,
      required this.optionId,
      required this.seatId,
      required this.paymentMethod,
      this.classType,
      this.coachId,
      this.journeyDate});

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  bool _isSuccess = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    try {
      // Phase 1: Wait 1.5s and call API
      final apiFuture = _apiService.confirmBooking(
          widget.optionId, widget.seatId, widget.paymentMethod, classType: widget.classType, coachId: widget.coachId, journeyDate: widget.journeyDate);
      await Future.delayed(const Duration(milliseconds: 1500));

      final response = await apiFuture;

      if (response['success'] == true) {
        if (!mounted) return;
        setState(() {
          _isSuccess = true;
        });

        // Phase 2: Show success for 0.5s then navigate
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => TicketScreen(bookingId: response['bookingId']),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isSuccess ? _buildSuccess() : _buildProcessing(),
      ),
    );
  }

  Widget _buildProcessing() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppTheme.primary),
        SizedBox(height: 24),
        Text('Processing payment...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Please do not close the app',
            style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              color: AppTheme.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 40),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        const Text('Payment Successful!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary))
            .animate()
            .fadeIn(delay: 200.ms),
      ],
    );
  }
}
