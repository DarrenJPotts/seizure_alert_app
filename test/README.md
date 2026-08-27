# Test suite

```bash
flutter test          # 153 Dart tests
cd functions && npm test   # 9 Cloud Functions tests (node:test, no deps)
```

## Layout

| Path | Covers |
|---|---|
| `core/helpers/` | `PhoneNumber` normalisation |
| `core/dtos/` | Serialisation round-trips for every DTO |
| `core/extensions/` | String, iterable, generic, and colour extensions |
| `core/services/` | `FirestoreService` against an in-memory Firestore |
| `features/home/` | Dashboard statistics |
| `features/formatters_test.dart` | Elapsed and remaining duration strings |
| `widgets/` | Presentational widgets and the SOS countdown |
| `support/` | Fixtures and pump helpers (not tests) |

`functions/test/` mirrors `core/helpers/phone_number_test.dart` case for case.
The client writes `phoneNormalized` and the functions query it, so the two
implementations must agree exactly — change one, change both.

## What is not covered, and why

**Anything reading `FirebaseAuth.instance`.** `FirestoreService` takes its
Firestore instance by injection but reads auth statically, so those paths need a
live Firebase app. This excludes `watchAlertResponses`, `HomeViewModel.firstName`
when no user is loaded, and the write paths on `SosViewModel` /
`HeadsUpViewModel` / `IncomingAlertViewModel`. Making auth injectable the way
Firestore already is would open all of it up.

**The Cloud Functions themselves.** `normalizePhone` is pure and tested;
`onAlertCreated`, `expireHeadsUpWindows`, `getPeopleIWatch`, `getAlertDetail`,
`sendCircleInvite`, and `respondToInvite` need `firebase-functions-test` plus the
Firestore emulator.

**`firestore.rules`.** Needs the emulator, which could not be started in the
environment these tests were written in (loopback sockets were blocked). The
rules compile server-side on deploy, but their behaviour is unverified —
`alert_responses` in particular is worth an emulator run, since a mismatch
between the read rule and the `watchAlertResponses` query shape denies the whole
stream rather than failing loudly.

Feature 28 raised the stakes here, so this is now the highest-value untested
surface in the repo. Worth asserting under the emulator, as a signed-in user who
is *not* in the circle:

- reading another user's `users`, `contacts`, `alerts`, `seizureLogs`, `headsUp` — denied
- writing `contacts.linkedUid`, on create and on update — denied (this is the
  authorization key for every cross-user read)
- any create or update on `alert_responses` — denied for all clients; writes go
  through the `submitAlertResponse` callable
- any read or write of `rate_limits` — denied
- and, as the alert owner, that reading your own `alert_responses` still works

**Account erasure.** `deleteMyData` (Cloud Function, Admin SDK) is the POPIA s24
path and has no automated coverage — it is a callable, so neither this suite nor
fake_cloud_firestore can reach it. Worth an emulator test that, for a user who
both owns alerts and has responded to someone else's:

- `users`, `contacts`, `seizureLogs`, `alerts`, `headsUp` scoped to them are gone
- `alert_responses` they wrote (`responderId`) *and* received (`alertOwnerId`) are gone
- `invites` naming them as sender or recipient are gone
- `rate_limits` documents prefixed with their uid are gone
- another user's contact row pointing at them survives, with `linkedUid` removed
  and `status` back to `pending`

**Screens.** Views wire themselves up through `Get.find`, so they need the full
DI graph registered. The presentational widgets they compose are covered.
