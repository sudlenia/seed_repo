import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_test/features/address/address_display.dart';

void main() {
  group('formatAddressForCell', () {
    const longAddress = '0x1234567890abcdef1234567890abcdef12345678';
    const longAddressNoPrefix = '1234567890abcdef1234567890abcdef12345678';
    const shortAddress = '0x1234';

    test('short address without 0x returns unchanged', () {
      expect(formatAddressForCell('0x1234', 1.0), '0x1234');
      expect(formatAddressForCell('0x', 1.0), '0x');
    });

    test('short address with 0x returns unchanged', () {
      expect(formatAddressForCell(shortAddress, 2.0), '0x1234');
    });

    test('long address with 0x is shortened as 6+4', () {
      final result = formatAddressForCell(longAddress, 1.0);
      expect(result, '0x123456…5678');
    });

    test('long address with 0x at textScaleFactor >= 1.6 is shortened as 4+4', () {
      final result = formatAddressForCell(longAddress, 2.0);
      expect(result, '0x1234…5678');
    });

    test('long address without 0x is shortened', () {
      final result = formatAddressForCell(longAddressNoPrefix, 1.0);
      expect(result, '123456…5678');
    });

    test('0x prefix is preserved', () {
      final result = formatAddressForCell(longAddress, 1.5);
      expect(result.startsWith('0x'), true);
      
      final resultNoPrefix = formatAddressForCell(longAddressNoPrefix, 1.5);
      expect(resultNoPrefix.startsWith('0x'), false);
    });

    test('boundary conditions', () {
      // Exactly 12 characters should not be shortened
      expect(formatAddressForCell('0x1234567890ab', 1.0), '0x1234567890ab');
      // 13 characters should be shortened
      expect(formatAddressForCell('0x1234567890abc', 1.0), '0x123456…90abc');
    });
  });
}