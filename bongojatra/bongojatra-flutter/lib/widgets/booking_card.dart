import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isArchived;
  final VoidCallback onViewTicket;
  final VoidCallback? onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    this.isArchived = false,
    required this.onViewTicket,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    Color stripColor;
    if (booking.type == 'BUS') {
      stripColor = AppTheme.busStrip;
    } else if (booking.type == 'TRAIN') {
      stripColor = AppTheme.trainStrip;
    } else {
      stripColor = AppTheme.launchStrip;
    }

    if (isArchived) {
      stripColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              color: stripColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.transportName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  isArchived ? Colors.grey : AppTheme.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(booking.seatClass,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(booking.origin,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isArchived
                                    ? Colors.grey
                                    : AppTheme.textDark)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              size: 16, color: Colors.grey),
                        ),
                        Text(booking.destination,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isArchived
                                    ? Colors.grey
                                    : AppTheme.textDark)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                            '${booking.bookedAt.split('T')[0]} • ${booking.departureTime}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event_seat,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Seat ${booking.seatId}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                        const Spacer(),
                        Text('৳${booking.price}',
                            style: TextStyle(
                                color:
                                    isArchived ? Colors.grey : AppTheme.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: onViewTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isArchived
                                ? Colors.grey.shade300
                                : AppTheme.primary,
                            foregroundColor:
                                isArchived ? Colors.black54 : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('View Ticket'),
                        ),
                        if (!isArchived &&
                            booking.status == 'CONFIRMED' &&
                            onCancel != null)
                          TextButton(
                            onPressed: onCancel,
                            child: const Text('Cancel',
                                style: TextStyle(color: AppTheme.secondary)),
                          ),
                        if (isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: booking.status == 'CANCELLED'
                                  ? AppTheme.secondary.withValues(alpha: 0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status,
                              style: TextStyle(
                                color: booking.status == 'CANCELLED'
                                    ? AppTheme.secondary
                                    : Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
