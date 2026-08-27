import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';

import '../../support/fixtures.dart';

void main() {
  group('AlertDetailDto responders', () {
    test('separates the caller from everyone else', () {
      final AlertDetailDto detail = Fixtures.alertDetail();

      expect(detail.notifiedCount, 3);
      expect(detail.responders, hasLength(2));
      expect(detail.callerResponse?.contactName, 'Jane Potts');
      expect(detail.callerResponse?.responding, isTrue);
      expect(detail.otherResponders, hasLength(1));
      expect(detail.otherResponders.single.contactName, 'Sipho Vilakazi');
    });

    test('has no caller row before the caller has responded', () {
      final Map<String, dynamic> map = Fixtures.alertDetailMap();
      map['responders'] = <Map<String, dynamic>>[
        <String, dynamic>{'contactName': 'Sipho Vilakazi', 'isCaller': false, 'seen': true},
      ];

      final AlertDetailDto detail = AlertDetailDto.fromMap(map);

      expect(detail.callerResponse, isNull);
      expect(detail.otherResponders, hasLength(1));
    });

    test('decodes a payload from a function that has no responder support', () {
      // The client may be newer than the deployed function. An absent
      // roster must read as "nobody yet", not crash the respond screen.
      final Map<String, dynamic> map = Fixtures.alertDetailMap()
        ..remove('responders')
        ..remove('notifiedCount');

      final AlertDetailDto detail = AlertDetailDto.fromMap(map);

      expect(detail.responders, isEmpty);
      expect(detail.notifiedCount, 0);
      expect(detail.callerResponse, isNull);
    });
  });

  group('OwnerProfileDto.carePlanSteps', () {
    OwnerProfileDto withNote(String? note) => OwnerProfileDto(displayName: 'A', emergencyNote: note);

    test('splits an emergency note into one step per line', () {
      final OwnerProfileDto owner = withNote(
        'Time the seizure.\nOver 5 minutes: give midazolam.\nRecovery position afterwards.',
      );

      expect(owner.carePlanSteps, <String>[
        'Time the seizure.',
        'Over 5 minutes: give midazolam.',
        'Recovery position afterwards.',
      ]);
    });

    test('strips numbering the person typed themselves', () {
      // The screen supplies its own step numbers, so a note written as a
      // numbered list must not render as "1. 1. Time the seizure".
      final OwnerProfileDto owner = withNote('1. Time the seizure.\n2) Call 10177.\n- Stay with them.\n• Keep calm.');

      expect(owner.carePlanSteps, <String>['Time the seizure.', 'Call 10177.', 'Stay with them.', 'Keep calm.']);
    });

    test('ignores blank lines and stray whitespace', () {
      final OwnerProfileDto owner = withNote('  Time it.  \n\n\n   \nStay with them.\n');

      expect(owner.carePlanSteps, <String>['Time it.', 'Stay with them.']);
    });

    test('is empty when there is no note, so the screen shows its empty state', () {
      // Deliberate: the respond screen must never substitute generic first
      // aid for instructions this person's neurologist gave them.
      expect(withNote(null).carePlanSteps, isEmpty);
      expect(withNote('').carePlanSteps, isEmpty);
      expect(withNote('   \n  ').carePlanSteps, isEmpty);
    });

    test('treats a single-line note as one step', () {
      expect(withNote('Do not restrain.').carePlanSteps, <String>['Do not restrain.']);
    });
  });

  group('OwnerProfileDto medical fields', () {
    test('decodes medications and the seizure-free count', () {
      final AlertDetailDto detail = Fixtures.alertDetail();

      expect(detail.ownerProfile.medications, <String>['Midazolam', 'Lamotrigine']);
      expect(detail.ownerProfile.daysSinceLastSeizure, 18);
    });

    test('defaults medications to empty rather than null', () {
      final OwnerProfileDto owner = OwnerProfileDto.fromMap(<String, dynamic>{'displayName': 'A'});

      expect(owner.medications, isEmpty);
      expect(owner.daysSinceLastSeizure, isNull);
    });
  });
}
