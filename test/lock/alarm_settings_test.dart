import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/features/lock/alarm_settings_provider.dart';
import 'package:medbuddy/features/lock/services/accessibility_lock_service.dart';

void main() {
  group('AlarmEnabledEnv.parseFlag', () {
    test('accepts the on spellings', () {
      for (final raw in ['on', 'ON', ' true ', '1']) {
        expect(AlarmEnabledEnv.parseFlag(raw), isTrue, reason: raw);
      }
    });

    test('accepts the off spellings', () {
      for (final raw in ['off', 'OFF', 'false', '0']) {
        expect(AlarmEnabledEnv.parseFlag(raw), isFalse, reason: raw);
      }
    });

    test('a typo falls through instead of silently disabling the alarm', () {
      // Returning false here would mean MEDBUDDY_ALARM=onn silently ships a
      // build that never rings — the exact failure a medication app cannot
      // afford. null lets the next source decide.
      expect(AlarmEnabledEnv.parseFlag('onn'), isNull);
      expect(AlarmEnabledEnv.parseFlag(''), isNull);
      expect(AlarmEnabledEnv.parseFlag('yes'), isNull);
    });
  });

  group('AlarmOutcome.tryParse', () {
    test('parses a skipped outcome', () {
      final o = AlarmOutcome.tryParse('med-1|skipped|1757000000000');
      expect(o, isNotNull);
      expect(o!.medicationId, 'med-1');
      expect(o.reason, AlarmEndReason.skipped);
      expect(o.endedAt.millisecondsSinceEpoch, 1757000000000);
    });

    test('parses a ceiling outcome', () {
      final o = AlarmOutcome.tryParse('med-2|ceiling|1757000000000');
      expect(o?.reason, AlarmEndReason.ceiling);
    });

    test('returns null on malformed entries rather than throwing', () {
      // One corrupt queue entry must not block the rest of the drain.
      expect(AlarmOutcome.tryParse('med-1|skipped'), isNull);
      expect(AlarmOutcome.tryParse('med-1|skipped|not-a-number'), isNull);
      expect(AlarmOutcome.tryParse('med-1|exploded|1757000000000'), isNull);
      expect(AlarmOutcome.tryParse(''), isNull);
    });

    test('tolerates an empty medication id', () {
      // The alarm can fire for a med the user deleted mid-window; the row
      // still needs writing, with a null medication_id.
      final o = AlarmOutcome.tryParse('|ceiling|1757000000000');
      expect(o, isNotNull);
      expect(o!.medicationId, '');
    });
  });
}
