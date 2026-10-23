import 'package:seizure_app/core/dtos/user_dto.dart';

enum MedicalCardField {
  name('Name'),
  bloodType('Blood type'),
  seizureType('Seizure type'),
  medications('Medications'),
  emergencyNote('Emergency note');

  const MedicalCardField(this.label);
  final String label;
}

/// An explicit allowlist: account identifiers, location, logs and contacts never
/// enter the card or the share payload.
class MedicalCardData {
  MedicalCardData(UserDto user)
    : values = Map.unmodifiable({
        MedicalCardField.name: user.displayName?.trim() ?? '',
        MedicalCardField.bloodType: user.bloodType?.trim() ?? '',
        MedicalCardField.seizureType: user.seizureType?.trim() ?? '',
        MedicalCardField.medications: (user.medications ?? [])
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .join(', '),
        MedicalCardField.emergencyNote: user.emergencyNote?.trim() ?? '',
      });
  final Map<MedicalCardField, String> values;
  Map<MedicalCardField, String> selected(Set<MedicalCardField> fields) => {
    for (final field in MedicalCardField.values)
      if (fields.contains(field) && values[field]!.isNotEmpty)
        field: values[field]!,
  };
  String shareText(Set<MedicalCardField> fields) => [
    'MEDICAL CARD',
    ...selected(
      fields,
    ).entries.map((entry) => '${entry.key.label}: ${entry.value}'),
    'Self-reported information. Not clinically verified.',
    'Shared from Seizure Alert.',
  ].join('\n\n');
}
