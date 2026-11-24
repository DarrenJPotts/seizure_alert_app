/// How the app stores moments in time (when a seizure, alert or response
/// happened) in Firestore.
///
/// The phone used to write local time with no offset ("2026-11-23T10:00:00"),
/// while the Cloud Functions and the watch wrote UTC ("...T08:00:00Z"). Mixed
/// together, sorting by the string misordered events by the UTC offset, the
/// server read local strings as UTC, and some screens showed UTC as if it were
/// local. Everything is now written in UTC and shown in local time.
///
/// Reading still accepts the old local strings: `DateTime.parse` treats a
/// string without an offset as local time, which is what those were.
library;

/// A moment in time, as stored: UTC ISO-8601 ending in `Z`.
String toStoredTimestamp(DateTime moment) => moment.toUtc().toIso8601String();

/// A stored moment, in local time.
DateTime parseStoredTimestamp(String value) => DateTime.parse(value).toLocal();

/// Like [parseStoredTimestamp], but null for a missing or unreadable value.
DateTime? tryParseStoredTimestamp(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
