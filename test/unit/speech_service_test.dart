import 'package:flutter_test/flutter_test.dart';

import 'package:healthcare_assistant/patterns/strategy/english_speech_strategy.dart';
import 'package:healthcare_assistant/patterns/strategy/chichewa_speech_strategy.dart';

void main() {
  group('Speech Strategy Pattern', () {
    test('English strategy language code', () {
      final strategy = EnglishSpeechStrategy();

      expect(strategy.languageCode, 'en-US');
    });

    test('Chichewa strategy language code', () {
      final strategy = ChichewaSpeechStrategy();

      expect(strategy.languageCode, 'ny-MW');
    });

    test('English strategy processes text', () {
      final strategy = EnglishSpeechStrategy();

      expect(strategy.processText('hello'), 'hello');
    });

    test('Chichewa strategy processes text', () {
      final strategy = ChichewaSpeechStrategy();

      expect(strategy.processText('moni'), 'moni');
    });
  });
}
