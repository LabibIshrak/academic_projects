import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transport_option.dart';
import '../theme/app_theme.dart';
import 'coach_selection_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  final TransportOption option;

  const ClassSelectionScreen({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    // Sort classes by price
    final sortedClasses = List.from(option.classes)
      ..sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(option.name, style: const TextStyle(fontSize: 18)),
            Text('${option.origin} → ${option.destination}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${option.departureTime} → ${option.arrivalTime}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ),
                Text(
                  option.durationText,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sortedClasses.length,
              itemBuilder: (context, index) {
                final cls = sortedClasses[index];
                
                int totalCoaches = cls.coaches.length;
                num totalAvailable = 0;
                for (var coach in cls.coaches) {
                  totalAvailable += coach.availableSeats;
                }

                bool isAC = cls.classType.contains('AC') || cls.classType.contains('SNIGDHA');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CoachSelectionScreen(
                            option: option,
                            trainClass: cls,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cls.classLabel,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark)),
                                const SizedBox(height: 4),
                                Text(
                                  cls.classType.replaceAll('_', ' '),
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                        totalAvailable > 0
                                            ? Icons.airline_seat_recline_normal
                                            : Icons.event_seat,
                                        size: 16,
                                        color: totalAvailable > 0
                                            ? AppTheme.primary
                                            : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalAvailable seats',
                                      style: TextStyle(
                                          color: totalAvailable > 0
                                              ? AppTheme.primary
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 16),
                                    if (isAC) ...[
                                      const Icon(Icons.ac_unit,
                                          size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      const Text('AC',
                                          style: TextStyle(color: Colors.blue)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalCoaches coach${totalCoaches > 1 ? 'es' : ''} available',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '৳${cls.price}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary),
                              ),
                              const SizedBox(height: 16),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
              },
            ),
          ),
        ],
      ),
    );
  }
}
