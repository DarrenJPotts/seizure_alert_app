abstract final class SupportConfig {
  static const String email = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'potts.darren@gmail.com',
  );

  // Placeholder until the public privacy policy is published.
  static const String privacyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://example.com/seizure-alert/privacy',
  );
}
