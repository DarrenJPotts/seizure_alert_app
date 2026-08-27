import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';

import '../../support/fixtures.dart';

/// The watch-list payload is assembled server-side in `getPeopleIWatch` and
/// decoded here. Nothing type-checks that boundary, so these tests pin the
/// shape — and, more importantly, pin the decision that a missing field
/// degrades to "don't show that bit" rather than to a broken screen.
void main() {
  group('WatchedPersonDto', () {
    test('decodes the context fields the caregiver card renders', () {
      final WatchedPersonDto person = Fixtures.watchedPerson();

      expect(person.headsUpNote, 'Feeling off, going to lie down.');
      expect(person.headsUpAt, DateTime(2026, 3, 14, 14, 20));
      expect(person.daysSinceLastSeizure, 18);
      expect(person.lastSeizureAt, DateTime(2026, 2, 24, 9));
      expect(person.lastAlertAt, DateTime(2026, 3, 14, 14, 20));
    });

    test('leaves every context field null when the server omits it', () {
      // What an older deployed function returns, or a person with no history.
      final WatchedPersonDto person = WatchedPersonDto.fromMap(<String, dynamic>{
        'ownerId': 'u',
        'ownerName': 'Someone',
        'contactId': 'c',
        'status': 'monitoring',
      });

      expect(person.headsUpNote, isNull);
      expect(person.headsUpAt, isNull);
      expect(person.daysSinceLastSeizure, isNull);
      expect(person.lastSeizureAt, isNull);
      expect(person.lastAlertAt, isNull);
      expect(person.ownerPhone, isNull);
    });

    test('survives an unparseable timestamp rather than throwing', () {
      final WatchedPersonDto person = WatchedPersonDto.fromMap(<String, dynamic>{
        'ownerId': 'u',
        'ownerName': 'Someone',
        'contactId': 'c',
        'status': 'sos',
        'lastAlertAt': 'not-a-date',
      });

      expect(person.lastAlertAt, isNull);
      expect(person.status, WatchedPersonStatus.sos);
    });
  });

  group('WatchListDto', () {
    test('decodes people and the merged activity feed', () {
      final WatchListDto list = Fixtures.watchList();

      expect(list.people, hasLength(1));
      expect(list.recentActivity, hasLength(2));
      expect(list.recentActivity.first.personName, 'Darren Potts');
      expect(list.recentActivity.first.at, DateTime(2026, 3, 14, 14, 20));
    });

    test('decodes an empty payload', () {
      final WatchListDto list = WatchListDto.fromMap(<String, dynamic>{});

      expect(list.people, isEmpty);
      expect(list.recentActivity, isEmpty);
    });

    test('drops activity events with no usable timestamp', () {
      // An event with no time cannot be placed in a time-ordered feed, and
      // rendering it undated would misrepresent when it happened.
      final WatchListDto list = WatchListDto.fromMap(<String, dynamic>{
        'people': <dynamic>[],
        'recentActivity': <Map<String, dynamic>>[
          <String, dynamic>{'personName': 'A', 'kind': 'sos', 'at': null},
          <String, dynamic>{'personName': 'B', 'kind': 'sos', 'at': '2026-03-14T08:00:00.000'},
        ],
      });

      expect(list.recentActivity, hasLength(1));
      expect(list.recentActivity.single.personName, 'B');
    });
  });

  group('WatchActivityDto.label', () {
    test('maps every alert type the app sends', () {
      // These three strings are the contract with AlertDto.type and
      // functions/index.js — an unmapped one must not render as a raw key.
      expect(_labelFor('sos'), 'SOS');
      expect(_labelFor('headsUp'), 'Heads Up');
      expect(_labelFor('headsUpExpired'), 'Check-in missed');
      expect(_labelFor('something-new'), 'SOS');
    });
  });
}

String _labelFor(String kind) => WatchActivityDto(personName: 'A', kind: kind, at: DateTime(2026)).label;
