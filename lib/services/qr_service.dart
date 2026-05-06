// ============================================================
// services/qr_service.dart
// Handles QR code data parsing and validation
// Expected QR payload format: "PARTICIPANT:<id>"
// ============================================================

class QRService {
  static const String _prefix = 'PARTICIPANT:';

  /// Parses a raw QR string and returns the participant ID.
  /// Returns null if the format is invalid.
  static String? parseParticipantId(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.startsWith(_prefix)) {
      final id = trimmed.substring(_prefix.length).trim();
      return id.isNotEmpty ? id : null;
    }
    return null;
  }

  /// Generates the expected QR payload for a given participant ID
  static String generatePayload(String participantId) {
    return '$_prefix$participantId';
  }

  /// Validates that a participant ID string is non-empty and well-formed
  static bool isValidParticipantId(String id) {
    return id.trim().isNotEmpty && id.length >= 3;
  }
}
