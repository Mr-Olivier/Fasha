import 'package:shared_preferences/shared_preferences.dart';

/// Survives the Android process death that can happen while the system
/// camera is in the foreground (see AttachmentPickerSheet and ChatScreen's
/// doc comments on retrieveLostData) - remembers WHICH booking's chat a
/// photo/video was being captured for, since everything normally held in
/// memory (including ChatScreen's own bookingId) is wiped along with the
/// rest of the killed process. SharedPreferences, not a Riverpod provider,
/// precisely because it needs to survive the process being gone entirely,
/// not just a widget being disposed.
class PendingAttachmentStore {
  PendingAttachmentStore._();

  static const _bookingIdKey = 'pending_chat_attachment_booking_id';
  static const _otherPartyNameKey = 'pending_chat_attachment_other_party_name';

  static Future<void> save({required String bookingId, required String otherPartyName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookingIdKey, bookingId);
    await prefs.setString(_otherPartyNameKey, otherPartyName);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookingIdKey);
    await prefs.remove(_otherPartyNameKey);
  }

  static Future<({String bookingId, String otherPartyName})?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = prefs.getString(_bookingIdKey);
    final otherPartyName = prefs.getString(_otherPartyNameKey);
    if (bookingId == null || otherPartyName == null) return null;
    return (bookingId: bookingId, otherPartyName: otherPartyName);
  }
}
