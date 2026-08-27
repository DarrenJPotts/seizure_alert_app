abstract final class PrivacyNotice {
  static const String version = '2026-08-27.draft-1';

  static const String title = 'How your information is used';

  static const String consentSummary =
      'I have read how my information is used and I agree to Seizure Alert '
      'storing my health information and sharing it with the emergency '
      'contacts I choose.';

  static const List<PrivacyNoticeSection> sections = <PrivacyNoticeSection>[
    PrivacyNoticeSection(
      heading: 'Who is responsible',
      body:
          'Agilebridge is the responsible party for the information this app '
          'collects. [PLACEHOLDER — add the registered entity name, physical '
          'address, and the Information Officer\'s contact details. POPIA s55 '
          'requires an Information Officer registered with the Information '
          'Regulator.]',
    ),
    PrivacyNoticeSection(
      heading: 'What is collected',
      body:
          'Your name, email address and phone number.\n\n'
          'Health information: the seizures you log, their duration and '
          'location, your blood type, seizure type, medications, and your '
          'emergency note.\n\n'
          'Your location, captured only at the moment you send an SOS or a '
          'Heads Up — the app does not track you continuously.\n\n'
          'The name and phone number of each emergency contact you add.',
    ),
    PrivacyNoticeSection(
      heading: 'Why it is collected',
      body:
          'To alert the people you nominate when you need help, and to show '
          'them what they need to know when they arrive: where you are, and '
          'the medical details you chose to record.\n\n'
          'Your seizure log exists so you can review your own history. It is '
          'not shared with your contacts.',
    ),
    PrivacyNoticeSection(
      heading: 'Who it is shared with',
      body:
          'Only the emergency contacts you add, and only when you send an '
          'alert or open a Heads Up. A contact who has the app must accept an '
          'invitation before they can see anything.\n\n'
          'During an active SOS, a responding contact can see your location, '
          'blood type, seizure type, medications and emergency note.',
    ),
    PrivacyNoticeSection(
      heading: 'Your emergency contacts',
      body:
          'When you add someone, you give us their name and phone number. '
          'Please only add people who have agreed to be contacted. POPIA gives '
          'them the same rights over their information as you have over yours.',
    ),
    PrivacyNoticeSection(
      heading: 'Where it is stored',
      body:
          'Google Firebase, operating as our processor under Google\'s Cloud '
          'Data Processing Addendum.\n\n'
          '[PLACEHOLDER — state the hosting region and the legal basis for any '
          'transfer outside South Africa. POPIA s72 governs transborder flows, '
          'and s57(1)(d) may require prior authorisation from the Information '
          'Regulator before special personal information leaves the country. '
          'This needs legal advice and must be resolved before launch.]',
    ),
    PrivacyNoticeSection(
      heading: 'How long it is kept',
      body:
          'Your information is kept while your account is open.\n\n'
          '[PLACEHOLDER — state the retention period for seizure logs and '
          'alert history. POPIA s14 requires records not be kept longer than '
          'necessary for the purpose.]',
    ),
    PrivacyNoticeSection(
      heading: 'Your rights',
      body:
          'You can see and correct your information at any time in Profile.\n\n'
          'You can delete your account and everything in it from Profile. '
          'Deletion is permanent and cannot be undone.\n\n'
          'You may ask what we hold about you, object to how it is used, or '
          'complain to the Information Regulator of South Africa.',
    ),
    PrivacyNoticeSection(
      heading: 'This app is not a medical device',
      body:
          'Seizure Alert does not detect seizures and cannot call an ambulance '
          'for you. It delivers alerts you trigger, and delivery depends on '
          'your phone, your signal and your contacts. Do not rely on it as '
          'your only safety measure.',
    ),
  ];
}

class PrivacyNoticeSection {
  const PrivacyNoticeSection({required this.heading, required this.body});

  final String heading;
  final String body;
}
