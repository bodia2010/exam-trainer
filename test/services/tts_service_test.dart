// Tests for TtsService.parseLines — splits "Speaker: text" dialogue into
// per-turn lines for sequential TTS synthesis/playback.
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_trainer/services/tts_service.dart';

void main() {
  final svc = TtsService.instance;

  group('parseLines — newline-separated turns (the common case)', () {
    test('splits alternating speakers on separate lines', () {
      final lines = svc.parseLines(
          'Chef: Guten Tag.\nZarif: Hallo.\nChef: Wie geht es Ihnen?');
      expect(lines.map((l) => (l.speaker, l.text)).toList(), [
        ('Chef', 'Guten Tag.'),
        ('Zarif', 'Hallo.'),
        ('Chef', 'Wie geht es Ihnen?'),
      ]);
    });

    test('joins a hyphenated word split across a hard-wrapped line', () {
      final lines = svc.parseLines('Chef: Wir müssen das neu ge-\nstalten.');
      expect(lines, hasLength(1));
      expect(lines.single.text, 'Wir müssen das neu gestalten.');
    });

    test('joins a plain sentence wrap with a single space', () {
      final lines = svc.parseLines('Chef: Das ist ein langer\nSatz.');
      expect(lines, hasLength(1));
      expect(lines.single.text, 'Das ist ein langer Satz.');
    });
  });

  group('parseLines — reproduces the live bug: multiple turns on ONE physical line',
      () {
    test(
        'four alternating Chef/Zarif turns crammed onto one line still split correctly',
        () {
      // Exact shape of the live failure: no '\n' between turns at all.
      const text = 'Chef: Eventuell könnte ich auch einmal an einem Tag '
          'früh und spät arbeiten. Ich arbeite ja immer im Frühdienst. '
          'Chef: Nein, das geht nicht. Das gibt es bei uns nicht. Nach '
          'sieben Stunden braucht jeder Fahrer eine Pause. Zarif: Aber '
          'ich habe gestern mit Jasna gesprochen. Sie arbeitet ja nur in '
          'Teilzeit und hätte Interesse, weitere Dienste zu übernehmen. '
          'Chef: Gut, danke für den Tipp.';
      final lines = svc.parseLines(text);
      expect(lines.map((l) => l.speaker).toList(),
          ['Chef', 'Chef', 'Zarif', 'Chef']);
      expect(lines[0].text, contains('Frühdienst.'));
      expect(lines[0].text, isNot(contains('Nein, das geht nicht')),
          reason: 'the second Chef turn must not be swallowed into the first');
      expect(lines[1].text, contains('Pause.'));
      expect(lines[2].text, contains('Teilzeit'));
      expect(lines[3].text, 'Gut, danke für den Tipp.');
    });

    test('does not split on a colon inside a quoted phrase mid-sentence', () {
      const text = 'Chef: Wir kennzeichnen diese Sendungen dann mit dem '
          'Begriff: „Wunschzeit gebucht". Zarif: Verstanden.';
      final lines = svc.parseLines(text);
      expect(lines.map((l) => l.speaker).toList(), ['Chef', 'Zarif']);
      expect(lines[0].text, contains('Wunschzeit gebucht'));
    });

    test('mixed: some turns newline-separated, some crammed together', () {
      const text = 'Chef: Erste Frage.\n'
          'Zarif: Erste Antwort. Chef: Zweite Frage.\n'
          'Zarif: Zweite Antwort.';
      final lines = svc.parseLines(text);
      expect(lines.map((l) => (l.speaker, l.text)).toList(), [
        ('Chef', 'Erste Frage.'),
        ('Zarif', 'Erste Antwort.'),
        ('Chef', 'Zweite Frage.'),
        ('Zarif', 'Zweite Antwort.'),
      ]);
    });
  });

  group('parseLines — monologue (no speaker prefixes)', () {
    test('tags every chunk with the detected narrator from a self-introduction',
        () {
      final lines = svc.parseLines(
          'Hallo, hier spricht Frau Meier. Ich rufe wegen der Bestellung an.');
      expect(lines, isNotEmpty);
      expect(lines.every((l) => l.speaker == 'Frau Meier'), isTrue);
    });

    test('falls back to an empty speaker when no narrator is detectable', () {
      final lines = svc.parseLines('Ein Text ohne jede Selbstvorstellung.');
      expect(lines, isNotEmpty);
      expect(lines.every((l) => l.speaker.isEmpty), isTrue);
    });
  });

  group('parseLines — edge cases', () {
    test('empty input returns no lines', () {
      expect(svc.parseLines(''), isEmpty);
      expect(svc.parseLines('   \n  \n '), isEmpty);
    });

    test('long single turn gets split into sentence-sized chunks, keeping the speaker',
        () {
      final sentence = List.generate(30, (i) => 'Satz Nummer $i.').join(' ');
      final lines = svc.parseLines('Chef: $sentence');
      expect(lines.length, greaterThan(1));
      expect(lines.every((l) => l.speaker == 'Chef'), isTrue);
      expect(lines.every((l) => l.text.length <= 400), isTrue);
    });
  });
}
