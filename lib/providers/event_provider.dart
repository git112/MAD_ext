// ============================================================
// providers/event_provider.dart
// Manages Event CRUD state via ChangeNotifier
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../services/hive_service.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;

  List<EventModel> get events => List.unmodifiable(_events);
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;

  /// Loads all events from Hive on startup
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    _events = HiveService.getAllEvents();

    // Auto-select first active event if none selected
    if (_selectedEvent == null && _events.isNotEmpty) {
      _selectedEvent = _events.firstWhere(
        (e) => e.isActive,
        orElse: () => _events.first,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Creates and persists a new event
  Future<void> createEvent({
    required String name,
    required DateTime dateTime,
    required int maxCapacity,
    String description = '',
  }) async {
    final event = EventModel(
      id: const Uuid().v4(),
      name: name,
      dateTime: dateTime,
      maxCapacity: maxCapacity,
      description: description,
    );

    await HiveService.saveEvent(event);
    _events.add(event);
    _selectedEvent ??= event; // Select first created event by default
    notifyListeners();
  }

  /// Updates an existing event
  Future<void> updateEvent(EventModel updated) async {
    await HiveService.saveEvent(updated);
    final idx = _events.indexWhere((e) => e.id == updated.id);
    if (idx != -1) _events[idx] = updated;
    if (_selectedEvent?.id == updated.id) _selectedEvent = updated;
    notifyListeners();
  }

  /// Deletes an event and resets selection
  Future<void> deleteEvent(String id) async {
    await HiveService.deleteEvent(id);
    _events.removeWhere((e) => e.id == id);
    if (_selectedEvent?.id == id) {
      _selectedEvent = _events.isNotEmpty ? _events.first : null;
    }
    notifyListeners();
  }

  /// Selects the active working event
  void selectEvent(EventModel event) {
    _selectedEvent = event;
    notifyListeners();
  }
}
