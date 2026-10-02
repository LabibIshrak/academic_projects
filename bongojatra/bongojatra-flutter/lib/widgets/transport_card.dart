import 'package:flutter/material.dart';
import '../models/transport_option.dart';
import '../theme/app_theme.dart';

class TransportCard extends StatelessWidget {
  final TransportOption option;
  final bool isAiPick;
  final VoidCallback onTap;

  const TransportCard({
    super.key,
    required this.option,
    this.isAiPick = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color stripColor;
    if (option.type == 'BUS') {
      stripColor = AppTheme.busStrip;
    } else if (option.type == 'TRAIN') {
      stripColor = AppTheme.trainStrip;
    } else {
      stripColor = AppTheme.launchStrip;
    }

    Color seatColor = Colors.red;
    if (option.availableSeats > 15) {
      seatColor = AppTheme.primary;
    } else if (option.availableSeats > 5) {
      seatColor = Colors.amber;
    }

    final bool isTrain = option.type == 'TRAIN';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored Strip
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
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              option.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAiPick)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('AI Pick',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                                isTrain ? 'TRAIN' : option.classType,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Middle Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Departure', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(option.departureTime,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                              Text(option.durationText,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Arrival', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(option.arrivalTime,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (isTrain) ...[
                        const Text('Multiple classes available',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: option.classes.map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.trainStrip.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${c.classLabel} ৳${c.price}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.trainStrip)),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        // Seats Row for Bus/Launch
                        Row(
                          children: [
                            Icon(Icons.event_seat, size: 14, color: seatColor),
                            const SizedBox(width: 4),
                            Text('${option.availableSeats} seats available',
                                style: TextStyle(
                                    color: seatColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Amenities Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: option.amenities
                            .map((a) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(a,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                  ],
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),

                      // Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('from ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('৳${option.price}',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
