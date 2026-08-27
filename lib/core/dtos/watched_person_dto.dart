enum WatchedPersonStatus { sos, headsUp, monitoring }

class WatchedPersonDto {
  final String ownerId;
  final String ownerName;
  final String? ownerPhone;
  final String contactId;
  final WatchedPersonStatus status;
  final String? activeAlertId;

  final String? headsUpNote;
  final DateTime? headsUpAt;

  final DateTime? lastSeizureAt;
  final int? daysSinceLastSeizure;
  final DateTime? lastAlertAt;

  WatchedPersonDto({
    required this.ownerId,
    required this.ownerName,
    this.ownerPhone,
    required this.contactId,
    required this.status,
    this.activeAlertId,
    this.headsUpNote,
    this.headsUpAt,
    this.lastSeizureAt,
    this.daysSinceLastSeizure,
    this.lastAlertAt,
  });

  factory WatchedPersonDto.fromMap(Map<String, dynamic> map) => WatchedPersonDto(
    ownerId: map['ownerId'] as String,
    ownerName: map['ownerName'] as String,
    ownerPhone: map['ownerPhone'] as String?,
    contactId: map['contactId'] as String,
    status: WatchedPersonStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => WatchedPersonStatus.monitoring,
    ),
    activeAlertId: map['activeAlertId'] as String?,
    headsUpNote: map['headsUpNote'] as String?,
    headsUpAt: parseTimestamp(map['headsUpAt']),
    lastSeizureAt: parseTimestamp(map['lastSeizureAt']),
    daysSinceLastSeizure: (map['daysSinceLastSeizure'] as num?)?.toInt(),
    lastAlertAt: parseTimestamp(map['lastAlertAt']),
  );
}

class WatchActivityDto {
  final String personName;
  final String kind;
  final DateTime at;

  WatchActivityDto({required this.personName, required this.kind, required this.at});

  static WatchActivityDto? fromMap(Map<String, dynamic> map) {
    final DateTime? at = parseTimestamp(map['at']);
    if (at == null) return null;
    return WatchActivityDto(
      personName: map['personName'] as String? ?? 'Someone',
      kind: map['kind'] as String? ?? 'sos',
      at: at,
    );
  }

  String get label {
    switch (kind) {
      case 'headsUp':
        return 'Heads Up';
      case 'headsUpExpired':
        return 'Check-in missed';
      default:
        return 'SOS';
    }
  }
}

class WatchListDto {
  final List<WatchedPersonDto> people;
  final List<WatchActivityDto> recentActivity;

  WatchListDto({required this.people, required this.recentActivity});

  factory WatchListDto.fromMap(Map<String, dynamic> map) => WatchListDto(
    people: (map['people'] as List? ?? <dynamic>[])
        .map((e) => WatchedPersonDto.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    recentActivity: (map['recentActivity'] as List? ?? <dynamic>[])
        .map((e) => WatchActivityDto.fromMap(Map<String, dynamic>.from(e as Map)))
        .whereType<WatchActivityDto>()
        .toList(),
  );
}

DateTime? parseTimestamp(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
