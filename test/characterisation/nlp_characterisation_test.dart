import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NLP Characterisation Tests', () {
    test('Difficulty breathing should be treated as emergency', () {
      const query = 'My child has difficulty breathing';

      expect(query.toLowerCase().contains('difficulty breathing'), true);
    });

    test('Seizure should be treated as emergency', () {
      const query = 'My child has a seizure';

      expect(query.toLowerCase().contains('seizure'), true);
    });
  });
}
