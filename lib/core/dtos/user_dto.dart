import 'package:seizure_app/core/helpers/phone_number.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';

class UserDto {
  UserDto({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.fcmToken,
    this.bloodType,
    this.seizureType,
    this.medications,
    this.emergencyNote,
    this.seizureActionPlan,
    this.rescueMedication,
    this.callEmergencyAfterMinutes = 5,
    this.nearbyAudibleAlert = false,
    this.medicationReminders = const <MedicationReminderDto>[],
    this.privacyConsentAt,
    this.privacyConsentVersion,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final String? fcmToken;
  final String? bloodType;
  final String? seizureType;
  final List<String>? medications;
  final String? emergencyNote;
  final String? seizureActionPlan;
  final String? rescueMedication;
  final int callEmergencyAfterMinutes;
  final bool nearbyAudibleAlert;
  final List<MedicationReminderDto> medicationReminders;

  final DateTime? privacyConsentAt;
  final String? privacyConsentVersion;

  /// E.164 form of [phone], written on every save so the Cloud Functions can
  /// match contacts to accounts by exact query. Never set directly — it is
  /// always derived from [phone] in [toMap].
  String? get phoneNormalized => PhoneNumber.normalize(phone);

  factory UserDto.fromMap(Map<String, dynamic> map) => UserDto(
    uid: map['uid'] as String,
    email: map['email'] as String,
    displayName: map['displayName'] as String?,
    photoUrl: map['photoUrl'] as String?,
    phone: map['phone'] as String?,
    fcmToken: map['fcmToken'] as String?,
    bloodType: map['bloodType'] as String?,
    seizureType: map['seizureType'] as String?,
    medications: (map['medications'] as List?)
        ?.map((e) => e.toString())
        .toList(),
    emergencyNote: map['emergencyNote'] as String?,
    seizureActionPlan: map['seizureActionPlan'] as String?,
    rescueMedication: map['rescueMedication'] as String?,
    callEmergencyAfterMinutes: map['callEmergencyAfterMinutes'] as int? ?? 5,
    nearbyAudibleAlert: map['nearbyAudibleAlert'] as bool? ?? false,
    medicationReminders: (map['medicationReminders'] as List? ?? <dynamic>[])
        .whereType<Map>()
        .map(
          (Map value) =>
              MedicationReminderDto.fromMap(Map<String, dynamic>.from(value)),
        )
        .toList(),
    privacyConsentAt: map['privacyConsentAt'] != null
        ? DateTime.tryParse(map['privacyConsentAt'] as String)
        : null,
    privacyConsentVersion: map['privacyConsentVersion'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'phone': phone,
    'phoneNormalized': phoneNormalized,
    'fcmToken': fcmToken,
    'bloodType': bloodType,
    'seizureType': seizureType,
    'medications': medications,
    'emergencyNote': emergencyNote,
    'seizureActionPlan': seizureActionPlan,
    'rescueMedication': rescueMedication,
    'callEmergencyAfterMinutes': callEmergencyAfterMinutes,
    'nearbyAudibleAlert': nearbyAudibleAlert,
    'medicationReminders': medicationReminders
        .map((MedicationReminderDto reminder) => reminder.toMap())
        .toList(),
    'privacyConsentAt': privacyConsentAt?.toIso8601String(),
    'privacyConsentVersion': privacyConsentVersion,
  };

  UserDto copyWith({
    String? displayName,
    String? photoUrl,
    String? phone,
    String? fcmToken,
    String? bloodType,
    String? seizureType,
    List<String>? medications,
    String? emergencyNote,
    String? seizureActionPlan,
    String? rescueMedication,
    int? callEmergencyAfterMinutes,
    bool? nearbyAudibleAlert,
    List<MedicationReminderDto>? medicationReminders,
    DateTime? privacyConsentAt,
    String? privacyConsentVersion,
  }) => UserDto(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    phone: phone ?? this.phone,
    fcmToken: fcmToken ?? this.fcmToken,
    bloodType: bloodType ?? this.bloodType,
    seizureType: seizureType ?? this.seizureType,
    medications: medications ?? this.medications,
    emergencyNote: emergencyNote ?? this.emergencyNote,
    seizureActionPlan: seizureActionPlan ?? this.seizureActionPlan,
    rescueMedication: rescueMedication ?? this.rescueMedication,
    callEmergencyAfterMinutes:
        callEmergencyAfterMinutes ?? this.callEmergencyAfterMinutes,
    nearbyAudibleAlert: nearbyAudibleAlert ?? this.nearbyAudibleAlert,
    medicationReminders: medicationReminders ?? this.medicationReminders,
    privacyConsentAt: privacyConsentAt ?? this.privacyConsentAt,
    privacyConsentVersion: privacyConsentVersion ?? this.privacyConsentVersion,
  );
}
