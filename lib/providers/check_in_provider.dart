// ============================================================
// providers/check_in_provider.dart
// Handles participant check-in logic with validation
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/participant_model.dart';
import '../models/check_in_log_model.dart';
import '../services/hive_service.dart';
import '../services/qr_service.dart';
import '../utils/dummy_data.dart';


/// Result object returned after a check-in attempt
class CheckInResult {
  final bool success;
  final String message;
  final ParticipantModel? participant;

  CheckInResult({
    required this.success,
    required this.message,
    this.participant,
  });
}

class CheckInProvider extends ChangeNotifier {
  List<ParticipantModel> _participants = [];
  List<CheckInLogModel> _logs = [];
  bool _isLoading = false;
  String _lastScanResult = '';

  List<ParticipantModel> get participants => List.unmodifiable(_participants);
  List<CheckInLogModel> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  String get lastScanResult => _lastScanResult;

  /// Loads participant and log data, seeding dummy data on first run
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _participants = HiveService.getAllParticipantsAll();
    _logs = HiveService.getAllLogs();

    // Seed dummy data if no participants exist
    if (_participants.isEmpty) {
      await DummyData.seed();
      _participants = HiveService.getAllParticipantsAll();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Registers a new participant for a specific event
  Future<void> registerParticipant({
    required String id,
    required String name,
    required String eventId,
    String? email,
    String? phone,
  }) async {
    final p = ParticipantModel(
      id: id,
      name: name,
      email: email ?? '',
      phone: phone ?? '',
      eventId: eventId,
      registeredAt: DateTime.now(),
    );
    await HiveService.saveParticipant(p);
    _participants.add(p);
    notifyListeners();
  }

  /// Returns participants for a specific event
  List<ParticipantModel> getParticipantsForEvent(String eventId) {
    return _participants.where((p) => p.eventId == eventId).toList();
  }

  /// Returns logs for a specific event
  List<CheckInLogModel> getLogsForEvent(String eventId) {
    return _logs
        .where((l) => l.eventId == eventId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Checks in a participant via QR scan
  Future<CheckInResult> checkInByQR({
    required String rawQrValue,
    required String eventId,
    required int maxCapacity,
  }) async {
    final participantId = QRService.parseParticipantId(rawQrValue);
    if (participantId == null) {
      return CheckInResult(success: false, message: 'Invalid QR code format.');
    }
    return _performCheckIn(
      participantId: participantId,
      eventId: eventId,
      maxCapacity: maxCapacity,
      method: CheckInMethod.qr,
    );
  }

  /// Checks in a participant via manual ID entry
  Future<CheckInResult> checkInManual({
    required String participantId,
    required String eventId,
    required int maxCapacity,
  }) async {
    if (!QRService.isValidParticipantId(participantId)) {
      return CheckInResult(
          success: false, message: 'Please enter a valid participant ID.');
    }
    return _performCheckIn(
      participantId: participantId.trim(),
      eventId: eventId,
      maxCapacity: maxCapacity,
      method: CheckInMethod.manual,
    );
  }

  /// Core check-in logic with all validation rules
  Future<CheckInResult> _performCheckIn({
    required String participantId,
    required String eventId,
    required int maxCapacity,
    required CheckInMethod method,
  }) async {
    debugPrint('--- Check-in Validation Started ---');
    debugPrint('Target ID: $participantId');
    debugPrint('Event ID: $eventId');

    // 1. Check if participant exists
    final participant = HiveService.getParticipant(participantId);
    if (participant == null) {
      debugPrint('Validation Failed: Participant not found.');
      return CheckInResult(
        success: false,
        message: 'Participant ID "$participantId" not found.',
      );
    }

    debugPrint('Participant Found: ${participant.name} (Registered for: ${participant.eventId})');

    // 2. Check if participant belongs to current event
    // Using trim() and case-insensitive check for eventId robustness if necessary,
    // though Hive keys are usually exact.
    if (participant.eventId.trim() != eventId.trim()) {
      debugPrint('Validation Failed: Event mismatch.');
      return CheckInResult(
        success: false,
        message: 'Registered for a different event (Event ID: ${participant.eventId})',
      );
    }

    // 3. Check if already checked-in
    if (HiveService.isAlreadyCheckedIn(participantId, eventId)) {
      debugPrint('Validation Failed: Duplicate entry.');
      return CheckInResult(
        success: false,
        message: 'Already checked in',
      );
    }

    // 4. Check capacity limit
    final currentCount = HiveService.checkedInCount(eventId);
    if (currentCount >= maxCapacity) {
      debugPrint('Validation Failed: Capacity reached ($currentCount/$maxCapacity).');
      return CheckInResult(
        success: false,
        message: 'Event full ($currentCount/$maxCapacity)',
      );
    }
    
    debugPrint('Validation Success! Proceeding with check-in...');

    // 5. Perform check-in – update participant record
    participant.isCheckedIn = true;
    await HiveService.updateParticipant(participant);

    // 6. Save log entry
    final log = CheckInLogModel(
      id: const Uuid().v4(),
      participantId: participantId,
      participantName: participant.name,
      eventId: eventId,
      method: method,
    );
    await HiveService.saveCheckInLog(log);

    // 7. Refresh local state
    _logs.insert(0, log);
    final idx = _participants.indexWhere((p) => p.id == participantId);
    if (idx != -1) _participants[idx] = participant;

    _lastScanResult = '✓ ${participant.name} checked in!';
    notifyListeners();

    return CheckInResult(
      success: true,
      message: '${participant.name} successfully checked in!',
      participant: participant,
    );
  }

  /// Searches participants by name or ID within an event
  List<ParticipantModel> search(String eventId, String query) {
    if (query.trim().isEmpty) return getParticipantsForEvent(eventId);
    return HiveService.searchParticipants(eventId, query);
  }

  void clearLastScan() {
    _lastScanResult = '';
    notifyListeners();
  }

  /// Helper for UI to simulate a QR scan with a dummy ID
  Future<CheckInResult> simulateQRScan({
    required String dummyId,
    required String eventId,
    required int maxCapacity,
  }) async {
    // Generate valid QR payload for simulation
    final payload = QRService.generatePayload(dummyId);
    return checkInByQR(
      rawQrValue: payload,
      eventId: eventId,
      maxCapacity: maxCapacity,
    );
  }
}
