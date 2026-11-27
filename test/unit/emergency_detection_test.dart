import 'package:flutter_test/flutter_test.dart';

import 'package:healthcare_assistant/patterns/chain/difficulty_breathing_handler.dart';
import 'package:healthcare_assistant/patterns/chain/seizure_handler.dart';
import 'package:healthcare_assistant/patterns/chain/bleeding_handler.dart';
import 'package:healthcare_assistant/patterns/chain/stroke_handler.dart';
import 'package:healthcare_assistant/patterns/chain/default_handler.dart';

void main() {
  group('Emergency Detection Chain Tests', () {
    late DifficultyBreathingHandler breathing;
    late SeizureHandler seizure;
    late BleedingHandler bleeding;
    late StrokeHandler stroke;
    late DefaultHandler fallback;

    setUp(() {
      breathing = DifficultyBreathingHandler();
      seizure = SeizureHandler();
      bleeding = BleedingHandler();
      stroke = StrokeHandler();
      fallback = DefaultHandler();

      breathing.setNext(seizure);
      seizure.setNext(bleeding);
      bleeding.setNext(stroke);
      stroke.setNext(fallback);
    });

    test('Detects difficulty breathing', () {
      expect(breathing.handle('my child has difficulty breathing'), true);
    });

    test('Detects seizure', () {
      expect(breathing.handle('my child had a seizure today'), true);
    });

    test('Detects severe bleeding', () {
      expect(breathing.handle('there is severe bleeding'), true);
    });

    test('Detects stroke symptoms', () {
      expect(breathing.handle('patient has slurred speech'), true);
    });

    test('Returns false for non-emergency query', () {
      expect(breathing.handle('how can i improve sleep quality'), false);
    });
  });
}
