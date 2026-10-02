import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/train_class.dart';
import '../models/transport_option.dart';
import '../theme/app_theme.dart';
import 'seat_selection_screen.dart';

class CoachSelectionScreen extends StatelessWidget {
  final TransportOption option;
  final TrainClass trainClass;

  const CoachSelectionScreen({
    super.key,
    required this.option,
    required this.trainClass,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Coach'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trainClass.classLabel,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16)),
                    Text('৳${trainClass.price}',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: trainClass.coaches.length,
              itemBuilder: (context, index) {
                final coach = trainClass.coaches[index];
                final double occupancy =
                    (coach.totalSeats - coach.availableSeats) /
                        coach.totalSeats;

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
                          builder: (_) => SeatSelectionScreen(
                            option: option,
                            classType: trainClass.classType,
                            coachId: coach.coachId,
                            coachLabel: coach.coachLabel,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                coach.coachLabel,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${coach.availableSeats}/${coach.totalSeats} available',
                            style: const TextStyle(
                                color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: occupancy,
                              backgroundColor: Colors.grey.shade200,
                              color: occupancy > 0.9
                                  ? AppTheme.secondary
                                  : AppTheme.primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY();
              },
            ),
          ),
        ],
      ),
    );
  }
}
