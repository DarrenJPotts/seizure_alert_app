abstract final class FirebaseCollectionKeys {
  static const String users = 'users';
  static const String contacts = 'contacts';
  static const String seizureLogs = 'seizureLogs';
  static const String alerts = 'alerts';
  static const String headsUp = 'headsUp';
  static const String responses = 'alert_responses';
  static const String wearableDevices = 'wearableDevices';
  static const String deliveries = 'alert_deliveries';

  /// Sub-collection under users/{uid}.
  static const String dailyLogs = 'dailyLogs';
}
