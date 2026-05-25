class UserDto {
  UserDto({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bloodType,
    this.seizureType,
    this.medications,
    this.emergencyNote,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? bloodType;
  final String? seizureType;
  final List<String>? medications;
  final String? emergencyNote;

  factory UserDto.fromMap(Map<String, dynamic> map) => UserDto(
    uid: map['uid'] as String,
    email: map['email'] as String,
    displayName: map['displayName'] as String?,
    photoUrl: map['photoUrl'] as String?,
    bloodType: map['bloodType'] as String?,
    seizureType: map['seizureType'] as String?,
    medications: (map['medications'] as List).map((e) => e.toString()).toList(),
    emergencyNote: map['emergencyNote'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'bloodType': bloodType,
    'seizureType': seizureType,
    'medications': medications,
    'emergencyNote': emergencyNote,
  };

  UserDto copyWith({
    String? displayName,
    String? photoUrl,
    String? bloodType,
    String? seizureType,
    List<String>? medications,
    String? emergencyNote,
  }) => UserDto(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    bloodType: bloodType ?? this.bloodType,
    seizureType: seizureType ?? this.seizureType,
    medications: medications ?? this.medications,
    emergencyNote: emergencyNote ?? this.emergencyNote,
  );
}