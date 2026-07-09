// Tests for two historically bug-prone helpers in ParseService:
// `_expandSentinels` (resolves the `<<SAME_AS_ORIGINAL>>` placeholder a
// reworked edition uses instead of repeating shared content) and
// `_mergeByVariant` (combines several raw parse results that share a
// variant_number/version into one final object). Reached through the
// `@visibleForTesting` wrappers declared next to them in
// parse_service.dart. Pure functions — no network/Firebase involved.
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/services/parse_service.dart';

void main() {
  final svc = ParseService.instance;

  // Mirrors ParseService._sameSentinel (private) — the two must stay in
  // sync by construction since it's a stable wire-format constant the
  // parse prompt also emits literally.
  const sentinel = '<<SAME_AS_ORIGINAL>>';

  group('_expandSentinels', () {
    test('expands a field-level sentinel from the base (no-version) object',
        () {
      final base = {
        'variant_number': 1,
        'texts': ['Originaltext hier.'],
      };
      final edition = {
        'variant_number': 1,
        'version': 'gekürzt',
        'texts': sentinel,
      };
      final expanded =
          svc.expandSentinelsForTest([base, edition], 'lesen_teil1');
      expect(expanded[1]['texts'], equals(['Originaltext hier.']));
    });

    test('expands a per-entry sentinel inside question_pairs (hoeren_teil1)',
        () {
      final pairA = {'dialogue': 'A'};
      final pairB = {'dialogue': 'B'};
      final pairC = {'dialogue': 'C'};
      final base = {
        'variant_number': 5,
        'question_pairs': [pairA, pairB, pairC],
      };
      final newPairB = {'dialogue': 'B geändert'};
      final edition = {
        'variant_number': 5,
        'version': 'v2',
        'question_pairs': [sentinel, newPairB, sentinel],
      };
      final expanded =
          svc.expandSentinelsForTest([base, edition], 'hoeren_teil1');
      final editionPairs = expanded[1]['question_pairs'] as List;
      expect(editionPairs[0], same(pairA));
      expect(editionPairs[1], same(newPairB));
      expect(editionPairs[2], same(pairC));
    });

    test(
        'leaves the literal sentinel in place when the base has no such '
        'field, instead of crashing', () {
      final base = {'variant_number': 1}; // no 'texts' field at all
      final edition = {
        'variant_number': 1,
        'version': 'v2',
        'texts': sentinel,
      };
      final expanded =
          svc.expandSentinelsForTest([base, edition], 'lesen_teil1');
      expect(expanded[1]['texts'], equals(sentinel));
    });
  });

  group('_mergeByVariant', () {
    test('merges two raw entries sharing variant_number and no version', () {
      final a = {
        'variant_number': 2,
        'texts': ['T1'],
        'questions': [
          {'number': 1, 'type': 'true_false', 'answer': 'richtig'},
        ],
      };
      final b = {
        'variant_number': 2,
        'option_pool': [
          {'letter': 'A'},
        ],
        'questions': [
          {'number': 2, 'type': 'true_false', 'answer': 'falsch'},
        ],
      };
      final merged = svc.mergeByVariantForTest([a, b]);
      expect(merged, hasLength(1));
      final item = merged.first as Map<String, dynamic>;
      expect(item['texts'], equals(['T1']));
      expect(
          item['option_pool'],
          equals([
            {'letter': 'A'}
          ]));
      expect(item['questions'], hasLength(2));
    });

    test('dedupes list entries sharing the same key field instead of '
        'duplicating them', () {
      final a = {
        'variant_number': 3,
        'questions': [
          {'number': 1, 'answer': 'richtig'},
        ],
      };
      final b = {
        'variant_number': 3,
        'questions': [
          {'number': 1, 'answer': 'DUPLICATE-SHOULD-BE-DROPPED'},
          {'number': 2, 'answer': 'falsch'},
        ],
      };
      final merged = svc.mergeByVariantForTest([a, b]);
      final questions = (merged.first as Map)['questions'] as List;
      expect(questions, hasLength(2));
      // Existing (first-seen) entry wins — the duplicate from b is dropped,
      // not used to overwrite it.
      expect((questions[0] as Map)['answer'], 'richtig');
      expect((questions[1] as Map)['number'], 2);
    });

    test('keeps distinct version labels as separate entries, original first',
        () {
      final original = {'variant_number': 1, 'texts': ['orig']};
      final editionB = {'variant_number': 1, 'version': 'B', 'texts': ['b']};
      final editionA = {'variant_number': 1, 'version': 'A', 'texts': ['a']};
      final merged =
          svc.mergeByVariantForTest([editionB, original, editionA]);
      expect(merged, hasLength(3));
      expect((merged[0] as Map)['version'], isNull);
      expect((merged[1] as Map)['version'], 'A');
      expect((merged[2] as Map)['version'], 'B');
    });

    test('sorts by variant_number ascending across different variants', () {
      final v2 = {'variant_number': 2};
      final v1 = {'variant_number': 1};
      final merged = svc.mergeByVariantForTest([v2, v1]);
      expect((merged[0] as Map)['variant_number'], 1);
      expect((merged[1] as Map)['variant_number'], 2);
    });
  });
}
