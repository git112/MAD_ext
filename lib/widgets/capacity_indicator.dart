// ============================================================
// widgets/capacity_indicator.dart
// Circular arc visual showing crowd occupancy level
// ============================================================
import 'package:flutter/material.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_theme.dart';

class CapacityIndicator extends StatelessWidget {
  final int checkedIn;
  final int maxCapacity;
  final CrowdStatus status;

  const CapacityIndicator({
    super.key,
    required this.checkedIn,
    required this.maxCapacity,
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case CrowdStatus.safe:
        return AppTheme.successColor;
      case CrowdStatus.moderate:
        return AppTheme.warningColor;
      case CrowdStatus.full:
        return AppTheme.dangerColor;
    }
  }

  String _statusLabel() {
    switch (status) {
      case CrowdStatus.safe:
        return 'SAFE';
      case CrowdStatus.moderate:
        return 'MODERATE';
      case CrowdStatus.full:
        return 'FULL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxCapacity > 0 ? checkedIn / maxCapacity : 0.0;
    final color = _statusColor();

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                strokeWidth: 16,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$checkedIn',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'capacity usage',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                _statusLabel(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
