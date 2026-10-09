class OnboardingInviteDto {
  const OnboardingInviteDto({
    required this.contactId,
    required this.contactName,
    required this.phone,
    required this.code,
  });

  final String contactId;
  final String contactName;
  final String phone;
  final String code;
}
