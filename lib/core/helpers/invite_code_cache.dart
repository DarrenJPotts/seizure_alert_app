/// One-time invite credentials stay in memory, scoped to the signed-in user.
class InviteCodeCache {
  InviteCodeCache({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  String? _owner;
  final _entries = <String, ({String code, DateTime expires})>{};

  void selectOwner(String? owner) {
    if (_owner == owner) return;
    clear();
    _owner = owner;
  }

  String? get(String contactId) {
    final entry = _entries[contactId];
    if (_owner == null || entry == null) return null;
    if (!entry.expires.isAfter(_now())) {
      invalidate(contactId);
      return null;
    }
    return entry.code;
  }

  void put(String contactId, String code, DateTime expires) {
    if (_owner != null && expires.isAfter(_now())) {
      _entries[contactId] = (code: code, expires: expires);
    }
  }

  void invalidate(String contactId) => _entries.remove(contactId);
  void retainContacts(Set<String> ids) =>
      _entries.removeWhere((id, _) => !ids.contains(id));
  void clear() {
    _entries.clear();
    _owner = null;
  }
}
