import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/booking_card.dart';
import 'ticket_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  List<Booking> _upcomingBookings = [];
  List<Booking> _archivedBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _apiService.getBookingHistory();
      if (mounted) {
        setState(() {
          _upcomingBookings =
              bookings.where((b) => b.status == 'CONFIRMED').toList();
          _archivedBookings = bookings
              .where((b) => b.status == 'CANCELLED' || b.status == 'COMPLETED')
              .toList();
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

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final success = await _apiService.cancelBooking(bookingId);
      if (!mounted) return;
      if (success) {
        _fetchBookings(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to cancel booking')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Journey'),
        content: const Text(
            'Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(bookingId);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Your Bookings',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.textDark,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Archived'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_upcomingBookings, false),
                          _buildList(_archivedBookings, true),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, bool isArchived) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isArchived ? Icons.history : Icons.confirmation_number_outlined,
                size: 64,
                color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(isArchived ? 'No archived journeys' : 'No upcoming journeys',
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            if (!isArchived)
              ElevatedButton(
                onPressed: () {
                  // The only way to switch to search tab is through HomeScreen's parent, but we can't easily access it from here without a callback.
                  // For now, this is static text.
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Go to Search tab to find routes')));
                },
                child: const Text('Start exploring routes'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          isArchived: isArchived,
          onViewTicket: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TicketScreen(bookingId: booking.bookingId)));
          },
          onCancel:
              isArchived ? null : () => _showCancelDialog(booking.bookingId),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index))
            .slideY(begin: 0.1);
      },
    );
  }
}
