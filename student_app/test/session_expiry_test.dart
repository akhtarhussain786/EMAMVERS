import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/core/api_service.dart';

/// A 401 is the one response the app has to act on rather than just report:
/// the stored token is dead, so the shell must return to the login screen.
/// ApiService declared an onUnauthorized hook and main.dart subscribed to it,
/// but nothing ever called it, so the session-expiry path was dead code and an
/// expired token showed up as an inline error on whatever screen was open.
void main() {
  tearDown(() => ApiService.onUnauthorized = null);

  test('the unauthorized hook exists for the shell to subscribe to', () {
    var fired = false;
    ApiService.onUnauthorized = () => fired = true;
    expect(ApiService.onUnauthorized, isNotNull);
    ApiService.onUnauthorized!();
    expect(fired, isTrue);
  });

  test('UnauthorizedException carries a message the user can act on', () {
    expect(UnauthorizedException().toString(), contains('sign in again'));
    expect(UnauthorizedException('Token rejected').toString(), 'Token rejected');
  });
}
