import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore from Pabna',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 8),
            const Text(
              'All 8 divisions + nearby cities',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ).animate().fadeIn(delay: 100.ms).slideX(),
            const SizedBox(height: 24),
            _buildDestinationCard(
              context,
              city: 'Dhaka',
              cityBn: 'ঢাকা',
              price: 250,
              color: const Color(0xFF1B4332),
              transports: ['BUS', 'TRAIN'],
            ).animate().fadeIn(delay: 200.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Chattogram',
              cityBn: 'চট্টগ্রাম',
              price: 600,
              color: const Color(0xFF2D6A4F),
              transports: ['BUS', 'TRAIN'],
            ).animate().fadeIn(delay: 300.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Rajshahi',
              cityBn: 'রাজশাহী',
              price: 80,
              color: const Color(0xFF40916C),
              transports: ['BUS', 'TRAIN'],
            ).animate().fadeIn(delay: 400.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Khulna',
              cityBn: 'খুলনা',
              price: 400,
              color: const Color(0xFF52B788),
              transports: ['BUS', 'TRAIN', 'LAUNCH'],
            ).animate().fadeIn(delay: 500.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Rangpur',
              cityBn: 'রংপুর',
              price: 300,
              color: const Color(0xFF74C69D),
              transports: ['BUS', 'TRAIN'],
            ).animate().fadeIn(delay: 600.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Sylhet',
              cityBn: 'সিলেট',
              price: 550,
              color: const Color(0xFF1B4332),
              transports: ['BUS', 'TRAIN'],
            ).animate().fadeIn(delay: 700.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Barisal',
              cityBn: 'বরিশাল',
              price: 400,
              color: const Color(0xFF2D6A4F),
              transports: ['BUS', 'LAUNCH'],
            ).animate().fadeIn(delay: 800.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Mymensingh',
              cityBn: 'ময়মনসিংহ',
              price: 280,
              color: const Color(0xFF40916C),
              transports: ['BUS'],
            ).animate().fadeIn(delay: 900.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Bogura',
              cityBn: 'বগুড়া',
              price: 180,
              color: const Color(0xFF52B788),
              transports: ['BUS', 'TRAIN'],
            ).animate().fadeIn(delay: 1000.ms).slideY(),
            const SizedBox(height: 16),
            _buildDestinationCard(
              context,
              city: 'Natore',
              cityBn: 'নাটোর',
              price: 50,
              color: const Color(0xFF74C69D),
              transports: ['BUS', 'TRAIN'],
            ).animate().fadeIn(delay: 1100.ms).slideY(),
            const SizedBox(height: 32),
            const Text(
              'TRAVEL TIPS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildTipCard('Silk City Express Snigdha class is the best Pabna→Dhaka train option'),
            _buildTipCard('BIWTC Rocket overnight to Barisal/Khulna is a unique river experience'),
            _buildTipCard('Natore and Ishwardi are within 1 hour by local bus'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context,
      {required String city,
      required String cityBn,
      required int price,
      required Color color,
      required List<String> transports}) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Go to Search and select $city')));
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Text(cityBn,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const Spacer(),
                Row(
                  children: transports
                      .map((t) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Text('from ৳$price',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.amber),
            const SizedBox(width: 16),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: AppTheme.textDark))),
          ],
        ),
      ),
    );
  }
}
