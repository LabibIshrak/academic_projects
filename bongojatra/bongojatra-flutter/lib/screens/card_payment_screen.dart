import 'package:flutter/material.dart';
import '../models/transport_option.dart';
import '../theme/app_theme.dart';
import 'payment_processing_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  final TransportOption option;
  final String seatId;

  final String? classType;
  final String? coachId;

  const CardPaymentScreen(
      {super.key, required this.option, required this.seatId, this.classType, this.coachId});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _cardNumber = '';
  String _cardName = '';
  String _cardExpiry = '';

  @override
  void initState() {
    super.initState();
    _numberController.addListener(
        () => setState(() => _cardNumber = _numberController.text));
    _nameController
        .addListener(() => setState(() => _cardName = _nameController.text));
    _expiryController.addListener(
        () => setState(() => _cardExpiry = _expiryController.text));
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onPay() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PaymentProcessingScreen(
        optionId: widget.option.id,
        seatId: widget.seatId,
        paymentMethod: 'Card',
        classType: widget.classType,
        coachId: widget.coachId,
        journeyDate: widget.option.journeyDate,
      ),
    ));
  }

  String _getCardType() {
    if (_cardNumber.startsWith('4')) return 'VISA';
    if (_cardNumber.startsWith('5')) return 'MASTERCARD';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cardType = _getCardType();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Dark navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            const Text('Card Payment', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Card Preview
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10))
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('BongoJatra',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                        if (cardType.isNotEmpty)
                          Text(cardType,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                    Text(
                      _cardNumber.isEmpty ? '**** **** **** 0000' : _cardNumber,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 2,
                          fontFamily: 'monospace'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CARDHOLDER',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                            Text(
                                _cardName.isEmpty
                                    ? 'JOHN DOE'
                                    : _cardName.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('EXPIRES',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                            Text(_cardExpiry.isEmpty ? 'MM/YY' : _cardExpiry,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Form
              Theme(
                data: ThemeData.dark().copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2)),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Card Number',
                          labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expiryController,
                            keyboardType: TextInputType.datetime,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: 'Expiry (MM/YY)',
                                labelStyle: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: 'CVV',
                                labelStyle: TextStyle(color: Colors.grey),
                                counterText: ''),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Pay ৳${widget.option.price}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
