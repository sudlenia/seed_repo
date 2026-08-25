import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_test/features/router/cards_auth_redirect.dart';

void main() {
  group('cardsAuthRedirect', () {
    test('not authenticated - /cards/card_1/issue?step=2 -> onboarding with next param', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards/card_1/issue?step=2'),
        false,
      );
      
      expect(
        result,
        '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
      );
    });

    test('authenticated - /onboarding with valid next -> redirect to next', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2'),
        true,
      );
      
      expect(
        result,
        '/cards/card_1/issue?step=2',
      );
    });

    test('authenticated - /onboarding with evil URL -> redirect to /cards', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding?next=https%3A%2F%2Fevil.com'),
        true,
      );
      
      expect(result, '/cards');
    });

    test('not authenticated - /onboarding -> null (prevent redirect loop)', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding'),
        false,
      );
      
      expect(result, null);
    });

    test('authenticated - /cards -> null (no redirect needed)', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards'),
        true,
      );
      
      expect(result, null);
    });

    test('authenticated - /wallet -> null (no redirect needed)', () {
      final result = cardsAuthRedirect(
        Uri.parse('/wallet'),
        true,
      );
      
      expect(result, null);
    });

    test('not authenticated - /wallet -> null (no redirect needed)', () {
      final result = cardsAuthRedirect(
        Uri.parse('/wallet'),
        false,
      );
      
      expect(result, null);
    });

    test('authenticated - /onboarding without next -> redirect to /cards', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding'),
        true,
      );
      
      expect(result, '/cards');
    });

    test('authenticated - /onboarding with empty next -> redirect to /cards', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding?next='),
        true,
      );
      
      expect(result, '/cards');
    });

    test('not authenticated - /cards -> redirect to onboarding', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards'),
        false,
      );
      
      expect(
        result,
        '/onboarding?next=%2Fcards',
      );
    });

    test('not authenticated - /cards/something -> redirect to onboarding', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards/something'),
        false,
      );
      
      expect(
        result,
        '/onboarding?next=%2Fcards%2Fsomething',
      );
    });
  });
}