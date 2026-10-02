import 'package:flutter/material.dart';
import '../models/transport_option.dart';
import 'payment_processing_screen.dart';

class BkashPaymentScreen extends StatefulWidget {
  final TransportOption option;
  final String seatId;

  final String? classType;
  final String? coachId;

  const BkashPaymentScreen(
      {super.key, required this.option, required this.seatId, this.classType, this.coachId});

  @override
  State<BkashPaymentScreen> createState() => _BkashPaymentScreenState();
}

class _BkashPaymentScreenState extends State<BkashPaymentScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onPay() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PaymentProcessingScreen(
        optionId: widget.option.id,
        seatId: widget.seatId,
        paymentMethod: 'bKash',
        classType: widget.classType,
        coachId: widget.coachId,
        journeyDate: widget.option.journeyDate,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const Color bkashColor = Color(0xFFE2136E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: bkashColor,
        title:
            const Text('bKash Payment', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text('bKash',
                    style: TextStyle(
                        color: bkashColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text('৳${widget.option.price}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                    '${widget.option.origin} → ${widget.option.destination}',
                    style: const TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'bKash Number',
                  hintText: '01XXXXXXXXX',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: bkashColor, width: 2)),
                  prefixIcon:
                      const Icon(Icons.phone_android, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 5,
                decoration: InputDecoration(
                  labelText: 'bKash PIN',
                  hintText: '5-digit PIN',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: bkashColor, width: 2)),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.grey),
                  counterText: '',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bkashColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Pay ৳${widget.option.price}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Demo payment — no real transaction',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
