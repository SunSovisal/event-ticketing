import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/auth/auth_linking.dart';

void main() {
  group('resolveAccountEmailForLinking', () {
    test('prefers password-provider email over Firebase and profile email', () {
      expect(
        resolveAccountEmailForLinking(
          passwordProviderEmail: ' emailA@gmail.com ',
          firebaseEmail: 'firebase@gmail.com',
          profileEmail: 'profile@gmail.com',
        ),
        'emailA@gmail.com',
      );
    });

    test('falls back to Firebase email, then profile email', () {
      expect(
        resolveAccountEmailForLinking(
          firebaseEmail: 'google@gmail.com',
          profileEmail: 'profile@gmail.com',
        ),
        'google@gmail.com',
      );
      expect(
        resolveAccountEmailForLinking(profileEmail: 'profile@gmail.com'),
        'profile@gmail.com',
      );
    });

    test('returns null when no email is available', () {
      expect(resolveAccountEmailForLinking(), isNull);
      expect(resolveAccountEmailForLinking(passwordProviderEmail: '  '), isNull);
    });
  });

  group('emailsDifferForLinking', () {
    test('is false when emails match ignoring case and spaces', () {
      expect(
        emailsDifferForLinking('EmailA@gmail.com', ' emaila@gmail.com '),
        isFalse,
      );
    });

    test('is true when both emails are present and different', () {
      expect(
        emailsDifferForLinking('emailA@gmail.com', 'emailB@gmail.com'),
        isTrue,
      );
    });

    test('is false when either email is missing', () {
      expect(emailsDifferForLinking(null, 'emailB@gmail.com'), isFalse);
      expect(emailsDifferForLinking('emailA@gmail.com', ''), isFalse);
    });
  });
}
