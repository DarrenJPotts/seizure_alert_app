import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/helpers/invite_code_cache.dart';

void main() {
  test('invite credentials expire and remain scoped to their owner', () {
    var now = DateTime.utc(2026, 10, 12);
    final cache = InviteCodeCache(now: () => now);
    cache.selectOwner('patient');
    cache.put('contact', '123456', now.add(const Duration(hours: 24)));
    expect(cache.get('contact'), '123456');
    now = now.add(const Duration(hours: 24));
    expect(cache.get('contact'), isNull);
    cache.put('contact', '654321', now.add(const Duration(hours: 24)));
    cache.selectOwner('another patient');
    expect(cache.get('contact'), isNull);
  });
  test('contact changes and sign-out remove cached credentials', () {
    final cache = InviteCodeCache();
    cache.selectOwner('patient');
    final expiry = DateTime.now().add(const Duration(hours: 1));
    cache.put('a', '123456', expiry);
    cache.put('b', '654321', expiry);
    cache.retainContacts({'a'});
    expect(cache.get('b'), isNull);
    cache.invalidate('a');
    expect(cache.get('a'), isNull);
    cache.put('a', '123456', expiry);
    cache.clear();
    expect(cache.get('a'), isNull);
  });
}
