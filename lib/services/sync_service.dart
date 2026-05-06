// ============================================================
// services/sync_service.dart
// Simulates background cloud sync logic.
// In a real app, replace with Firebase Firestore calls.
// ============================================================
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'hive_service.dart';

class SyncService {
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  /// Starts periodic sync check every 30 seconds
  static void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _attemptSync(),
    );
  }

  static void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Attempts to sync pending records if online
  static Future<void> _attemptSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final results = await Connectivity().checkConnectivity();
      final isOnline = !results.contains(ConnectivityResult.none) ||
          results.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        await _syncPendingLogs();
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Syncs all unsynced check-in logs
  /// In production: push each log to Firestore, then mark as synced
  static Future<void> _syncPendingLogs() async {
    final unsynced = HiveService.getUnsyncedLogs();

    for (final log in unsynced) {
      // TODO: Replace with real Firestore push
      // await FirebaseFirestore.instance.collection('check_in_logs').doc(log.id).set({...});

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      await HiveService.markSynced(log.id);
    }
  }

  /// Manual trigger for immediate sync attempt
  static Future<String> triggerSync() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final isOnline = results.any((r) => r != ConnectivityResult.none);

      if (!isOnline) {
        return 'Offline – sync will happen automatically when connected.';
      }

      final unsynced = HiveService.getUnsyncedLogs();
      if (unsynced.isEmpty) {
        return 'Everything is already synced!';
      }

      await _syncPendingLogs();
      return 'Synced ${unsynced.length} record(s) successfully.';
    } catch (e) {
      return 'Sync error: $e';
    }
  }
}
