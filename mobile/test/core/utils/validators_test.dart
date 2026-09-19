import 'package:flutter_test/flutter_test.dart';
import 'package:fasha/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () {
      expect(Validators.email(''), 'Email is required');
    });

    test('rejects a malformed address', () {
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('alice@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty', () {
      expect(Validators.password(''), 'Password is required');
    });

    test('rejects fewer than 8 characters', () {
      expect(Validators.password('short'), 'Use at least 8 characters');
    });

    test('accepts 8 or more characters', () {
      expect(Validators.password('password123'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects a mismatch', () {
      expect(Validators.confirmPassword('different', 'password123'), "Passwords don't match");
    });

    test('accepts a match', () {
      expect(Validators.confirmPassword('password123', 'password123'), isNull);
    });
  });

  group('Validators.phone', () {
    test('is optional - null is fine', () {
      expect(Validators.phone(null), isNull);
      expect(Validators.phone(''), isNull);
    });

    test('accepts a bare 9-digit number (RegisterScreen has its own +250 prefix)', () {
      expect(Validators.phone('788123456'), isNull);
    });

    test('accepts a leading-0 10-digit number', () {
      expect(Validators.phone('0788123456'), isNull);
    });

    test('accepts a full +250 prefix', () {
      expect(Validators.phone('+250788123456'), isNull);
    });

    test('rejects an invalid number', () {
      expect(Validators.phone('12345'), isNotNull);
    });
  });

  group('Validators.price', () {
    test('rejects empty', () {
      expect(Validators.price(''), 'Price is required');
    });

    test('rejects non-numeric input', () {
      expect(Validators.price('abc'), 'Enter a valid number');
    });

    test('rejects zero', () {
      expect(Validators.price('0'), 'Price must be greater than zero');
    });

    test('rejects negative numbers', () {
      expect(Validators.price('-5'), 'Price must be greater than zero');
    });

    test('accepts a positive number', () {
      expect(Validators.price('15000'), isNull);
    });
  });
}
