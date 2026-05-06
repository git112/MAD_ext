// ============================================================
// services/hive_service.dart
// Central service for all Hive box operations (CRUD)
// ============================================================
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event_model.dart';
import '../models/participant_model.dart';
import '../models/check_in_log_model.dart';

class HiveService {
  // Box names
  static const String eventsBox = 'events';
  static const String participantsBox = 'participants';
  static const String checkInLogsBox = 'check_in_logs';

  // Open all Hive boxes at startup
  static Future<void> init() async {
    await Hive.openBox<EventModel>(eventsBox);
    await Hive.openBox<ParticipantModel>(participantsBox);
    await Hive.openBox<CheckInLogModel>(checkInLogsBox);
  }

  // ---- EVENT CRUD ----

  static Box<EventModel> get _events => Hive.box<EventModel>(eventsBox);

  static Future<void> saveEvent(EventModel event) async {
    await _events.put(event.id, event);
  }

  static List<EventModel> getAllEvents() {
    return _events.values.toList();
  }

  static EventModel? getEvent(String id) {
    return _events.get(id);
  }

  static Future<void> deleteEvent(String id) async {
    await _events.delete(id);
  }

  // ---- PARTICIPANT CRUD ----

  static Box<ParticipantModel> get _participants =>
      Hive.box<ParticipantModel>(participantsBox);

  static Future<void> saveParticipant(ParticipantModel participant) async {
    await _participants.put(participant.id, participant);
  }

  static List<ParticipantModel> getParticipantsByEvent(String eventId) {
    return _participants.values
        .where((p) => p.eventId == eventId)
        .toList();
  }

  /// Returns all participants across all events
  static List<ParticipantModel> getAllParticipantsAll() {
    return _participants.values.toList();
  }

  static ParticipantModel? getParticipant(String id) {
    return _participants.get(id);
  }

  static Future<void> updateParticipant(ParticipantModel participant) async {
    await _participants.put(participant.id, participant);
  }

  static List<ParticipantModel> searchParticipants(
      String eventId, String query) {
    final q = query.toLowerCase();
    return _participants.values
        .where((p) =>
            p.eventId == eventId &&
            (p.name.toLowerCase().contains(q) ||
                p.id.toLowerCase().contains(q)))
        .toList();
  }

  // ---- CHECK-IN LOG CRUD ----

  static Box<CheckInLogModel> get _logs =>
      Hive.box<CheckInLogModel>(checkInLogsBox);

  static Future<void> saveCheckInLog(CheckInLogModel log) async {
    await _logs.put(log.id, log);
  }

  static List<CheckInLogModel> getLogsByEvent(String eventId) {
    return _logs.values
        .where((l) => l.eventId == eventId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static List<CheckInLogModel> getUnsyncedLogs() {
    return _logs.values.where((l) => !l.isSynced).toList();
  }

  /// Returns all logs across all events
  static List<CheckInLogModel> getAllLogs() {
    return _logs.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Mark a log entry as synced to cloud
  static Future<void> markSynced(String logId) async {
    final log = _logs.get(logId);
    if (log != null) {
      log.isSynced = true;
      await log.save();
    }
  }

  /// Whether participant has already checked in for the event
  static bool isAlreadyCheckedIn(String participantId, String eventId) {
    return _logs.values
        .any((l) => l.participantId == participantId && l.eventId == eventId);
  }

  /// Count checked-in participants for an event
  static int checkedInCount(String eventId) {
    // Count unique participantIds in logs for this event
    return _logs.values
        .where((l) => l.eventId == eventId)
        .map((l) => l.participantId)
        .toSet()
        .length;
  }

  /// Clears all data from all boxes (Hard Reset)
  static Future<void> clearAllData() async {
    await _events.clear();
    await _participants.clear();
    await _logs.clear();
  }
}
