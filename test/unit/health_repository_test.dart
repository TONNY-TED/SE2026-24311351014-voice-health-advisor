import 'package:flutter_test/flutter_test.dart';

import 'package:healthcare_assistant/patterns/repository/local_health_repository.dart';

void main() {
  group('Repository Pattern', () {
    test('LocalHealthRepository can be created', () {
      final repository = LocalHealthRepository();

      expect(repository, isNotNull);
    });
  });
}