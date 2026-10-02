import 'package:flutter/material.dart';
import '../models/seat.dart';
import '../theme/app_theme.dart';

class SeatWidget extends StatelessWidget {
  final Seat seat;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;
  final String label;

  const SeatWidget({
    super.key,
    required this.seat,
    required this.isSelected,
    this.onTap,
    this.size = 44,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    bool isAvailable = seat.status == 'AVAILABLE';

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (!isAvailable) {
      bgColor = const Color(0xFFE8ECEF);
      borderColor = Colors.grey.shade400;
      textColor = Colors.grey;
    } else if (isSelected) {
      bgColor = AppTheme.primary;
      borderColor = AppTheme.primary;
      textColor = Colors.white;
    } else {
      bgColor = seat.isWindow
          ? AppTheme.primary.withValues(alpha: 0.05)
          : Colors.white;
      borderColor = AppTheme.primary;
      textColor = AppTheme.textDark;
    }

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: size > 40 ? 14 : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
