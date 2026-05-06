// ============================================================
// providers/dashboard_provider.dart
// Computes and exposes dashboard statistics for the selected event
// ============================================================
import 'package:flutter/foundation.dart';
import '../services/hive_service.dart';
import '../models/event_model.dart';

/// Crowd status level for visual indicator
enum CrowdStatus { safe, moderate, full }

class DashboardProvider extends ChangeNotifier {
  int _maxCapacity = 0;
  int _totalParticipants = 0;
  int _checkedIn = 0;

  int get totalParticipants => _totalParticipants;
  int get checkedIn => _checkedIn;
  int get remaining => (_maxCapacity - _checkedIn).clamp(0, _maxCapacity);
  int get maxCapacity => _maxCapacity;
  double get occupancyRatio =>
      _maxCapacity > 0 ? _checkedIn / _maxCapacity : 0.0;

  /// Returns the crowd status based on occupancy ratio
  CrowdStatus get crowdStatus {
    if (occupancyRatio < 0.7) return CrowdStatus.safe;
    if (occupancyRatio < 0.9) return CrowdStatus.moderate;
    return CrowdStatus.full;
  }

  /// Call this whenever the selected event changes or a new check-in happens
  void refresh(EventModel event) {
    _maxCapacity = event.maxCapacity;
    _totalParticipants = HiveService.getParticipantsByEvent(event.id).length;
    _checkedIn = HiveService.checkedInCount(event.id);
    notifyListeners();
  }
}
