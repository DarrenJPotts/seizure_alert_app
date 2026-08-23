import 'package:seizure_app/core/helpers/phone_number.dart';

enum ContactStatus { active, pending }

class ContactDto {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? relation;
  final int priority;
  final bool notifyViaSms;
  final bool notifyViaPush;
  final DateTime createdAt;
  final ContactStatus status;

  /// E.164 form of [phone] — the field every cross-user lookup queries on.
  /// Derived rather than stored so no write path can forget to set it.
  String? get phoneNormalized => PhoneNumber.normalize(phone);

  ContactDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.relation,
    this.priority = 0,
    this.notifyViaSms = true,
    this.notifyViaPush = true,
    required this.createdAt,
    this.status = ContactStatus.active,
  });

  factory ContactDto.fromMap(Map<String, dynamic> map) => ContactDto(
    id: map['id'] as String,
    userId: map['userId'] as String,
    name: map['name'] as String,
    phone: map['phone'] as String,
    relation: map['relation'] as String?,
    priority: map['priority'] as int? ?? 0,
    notifyViaSms: map['notifyViaSms'] as bool? ?? true,
    notifyViaPush: map['notifyViaPush'] as bool? ?? true,
    createdAt: DateTime.parse(map['createdAt'] as String),
    status: ContactStatus.values.firstWhere(
      (ContactStatus e) => e.name == map['status'],
      orElse: () => ContactStatus.active,
    ),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'phone': phone,
    'phoneNormalized': phoneNormalized,
    'relation': relation,
    'priority': priority,
    'notifyViaSms': notifyViaSms,
    'notifyViaPush': notifyViaPush,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };
}