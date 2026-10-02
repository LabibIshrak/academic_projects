import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class TicketScreen extends StatefulWidget {
  final String bookingId;

  const TicketScreen({super.key, required this.bookingId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final TicketService _ticketService = TicketService();

  bool _isLoading = true;
  String? _error;
  Booking? _booking;
  String _passengerName = '';

  @override
  void initState() {
    super.initState();
    _fetchBooking();
  }

  Future<void> _fetchBooking() async {
    try {
      final name = await _authService.getName();
      final history = await _apiService.getBookingHistory();
      final booking =
          history.firstWhere((b) => b.bookingId == widget.bookingId);

      if (mounted) {
        setState(() {
          _booking = booking;
          _passengerName = name ?? 'Traveler';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_booking == null) return;

    try {
      final pdfBytes =
          await _ticketService.generateTicketPdf(_booking!, _passengerName);
      await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'BongoJatra_Ticket_${_booking!.bookingId}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Your Ticket'),
        automaticallyImplyLeading: false, // Don't allow back to processing
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildTicketPreview(),
      bottomNavigationBar: _booking != null ? _buildBottomActions() : null,
    );
  }

  Widget _buildTicketPreview() {
    Color transportColor = AppTheme.launchStrip;
    if (_booking!.type == 'BUS') transportColor = AppTheme.busStrip;
    if (_booking!.type == 'TRAIN') transportColor = AppTheme.trainStrip;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BongoJatra',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('বাংলাদেশের যোগাযোগ ব্যবস্থা',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: transportColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(_booking!.type,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Red Stripe
            Container(height: 4, color: AppTheme.secondary),
            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('PASSENGER: ',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(_passengerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(_booking!.origin,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: Colors.grey),
                      ),
                      Text(_booking!.destination,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn(
                          'Journey Date', _booking!.journeyDate ?? _booking!.bookedAt.split('T')[0]),
                      _buildInfoColumn('Departure', _booking!.departureTime),
                      _buildInfoColumn('Arrival', _booking!.arrivalTime),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Operator', _booking!.operator),
                      _buildInfoColumn('Class', _booking!.coachId != null ? '${_booking!.seatClass} (${_booking!.coachId})' : _booking!.seatClass),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seat',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(_booking!.seatId,
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoColumn('Booked on', _booking!.bookedAt.split('.')[0].replaceAll('T', ' at ')),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child:
                        Divider(color: Colors.black12, thickness: 1, height: 1),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_booking!.bookingId,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Text('৳${_booking!.price}',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      QrImageView(
                        data: _booking!.bookingId,
                        version: QrVersions.auto,
                        size: 80.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Valid for date of travel only',
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppTheme.secondary, shape: BoxShape.circle)),
                  Text('Payment: ${_booking!.paymentMethod}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _downloadPdf,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primary),
              ),
              child: const Text('Download PDF',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
