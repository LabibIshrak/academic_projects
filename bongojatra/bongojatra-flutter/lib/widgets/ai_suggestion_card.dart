import 'package:flutter/material.dart';
import '../models/route_response.dart';
import '../theme/app_theme.dart';

class AiSuggestionCard extends StatelessWidget {
  final AISuggestion suggestion;

  const AiSuggestionCard({
    super.key,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(
          left: BorderSide(color: AppTheme.primary, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('AI Suggestion',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(suggestion.recommendation,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(suggestion.reason,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(suggestion.tip,
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
