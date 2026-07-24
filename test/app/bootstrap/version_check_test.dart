import 'package:flutter_test/flutter_test.dart';
import 'package:soom_mobile/app/bootstrap/version_check.dart';

void main() {
  group('compare', () {
    test('orders by major, minor, then patch', () {
      expect(VersionCheck.compare('1.0.0', '2.0.0'), isNegative);
      expect(VersionCheck.compare('1.2.0', '1.3.0'), isNegative);
      expect(VersionCheck.compare('1.2.3', '1.2.4'), isNegative);
      expect(VersionCheck.compare('2.0.0', '1.9.9'), isPositive);
      expect(VersionCheck.compare('1.2.3', '1.2.3'), isZero);
    });

    test('compares numerically, not lexically', () {
      // The classic trap: "10" sorts before "9" as a string.
      expect(VersionCheck.compare('1.10.0', '1.9.0'), isPositive);
      expect(VersionCheck.compare('1.0.10', '1.0.9'), isPositive);
    });

    test('treats missing segments as zero', () {
      expect(VersionCheck.compare('1.2', '1.2.0'), isZero);
      expect(VersionCheck.compare('1', '1.0.0'), isZero);
      expect(VersionCheck.compare('1.2', '1.2.1'), isNegative);
    });

    test('ignores the build suffix', () {
      expect(VersionCheck.compare('1.2.3+45', '1.2.3'), isZero);
      expect(VersionCheck.compare('1.2.3+1', '1.2.3+99'), isZero);
    });

    test('tolerates malformed segments instead of throwing', () {
      // A bad version from the backend must not crash startup.
      expect(() => VersionCheck.compare('1.x.3', '1.0.3'), returnsNormally);
      expect(VersionCheck.compare('1.x.3', '1.0.3'), isZero);
      expect(() => VersionCheck.compare('', '1.0.0'), returnsNormally);
    });

    test('handles surrounding whitespace', () {
      expect(VersionCheck.compare(' 1.2.3 ', '1.2.3'), isZero);
    });
  });

  group('isUpdateRequired', () {
    test('true when the build is older than the floor', () {
      expect(
        VersionCheck.isUpdateRequired(
          current: '1.0.0',
          minimumSupported: '1.1.0',
        ),
        isTrue,
      );
    });

    test('false when the build meets or exceeds the floor', () {
      expect(
        VersionCheck.isUpdateRequired(
          current: '1.1.0',
          minimumSupported: '1.1.0',
        ),
        isFalse,
      );
      expect(
        VersionCheck.isUpdateRequired(
          current: '2.0.0',
          minimumSupported: '1.1.0',
        ),
        isFalse,
      );
    });

    test('false when the backend specifies no floor', () {
      // Never lock users out because a config value is missing.
      expect(
        VersionCheck.isUpdateRequired(current: '1.0.0', minimumSupported: null),
        isFalse,
      );
      expect(
        VersionCheck.isUpdateRequired(current: '1.0.0', minimumSupported: ''),
        isFalse,
      );
      expect(
        VersionCheck.isUpdateRequired(current: '1.0.0', minimumSupported: '  '),
        isFalse,
      );
    });

    test('ignores the build suffix on the installed version', () {
      expect(
        VersionCheck.isUpdateRequired(
          current: '1.1.0+30',
          minimumSupported: '1.1.0',
        ),
        isFalse,
      );
    });
  });
}
