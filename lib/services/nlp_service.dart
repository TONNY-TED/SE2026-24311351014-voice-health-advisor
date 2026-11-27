import 'knowledge_base_service.dart';

import '../patterns/chain/difficulty_breathing_handler.dart';
import '../patterns/chain/seizure_handler.dart';
import '../patterns/chain/bleeding_handler.dart';
import '../patterns/chain/stroke_handler.dart';
import '../patterns/chain/default_handler.dart';

enum NlpIntent {
  emergency,
  symptomInfo,
  prevention,
  nutrition,
  medication,
  careGuidance,
  wellness,
  unknown,
}

class NlpResult {
  final KbEntry? entry;
  final String topic;
  final String condition;
  final String category;
  final NlpIntent intent;
  final double confidence;

  bool get isEmergency => intent == NlpIntent.emergency;

  const NlpResult({
    required this.entry,
    required this.topic,
    required this.condition,
    required this.category,
    required this.intent,
    required this.confidence,
  });

  factory NlpResult.unknown() => const NlpResult(
        entry: null,
        topic: '',
        condition: '',
        category: '',
        intent: NlpIntent.unknown,
        confidence: 0.0,
      );
}

class NlpService {
  static bool isEmergencyQuery(String norm) {
    final breathing = DifficultyBreathingHandler();
    final seizure = SeizureHandler();
    final bleeding = BleedingHandler();
    final stroke = StrokeHandler();
    final fallback = DefaultHandler();

    breathing.setNext(seizure);
    seizure.setNext(bleeding);
    bleeding.setNext(stroke);
    stroke.setNext(fallback);

    return breathing.handle(norm);
  }

  static String normalize(String input) {
    var s = input.toLowerCase();

    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  static NlpResult parse(
    String query,
    List<KbEntry> entries,
  ) {
    final norm = normalize(query);

    if (norm.isEmpty || entries.isEmpty) {
      return NlpResult.unknown();
    }

    // Emergency path using Chain of Responsibility
    if (isEmergencyQuery(norm)) {
      final s001 = _findById(entries, 'S001');

      final entry = s001 ?? _bestByScore(norm, entries);

      if (entry != null) {
        return NlpResult(
          entry: entry,
          topic: entry.topic,
          condition: entry.condition,
          category: entry.category,
          intent: NlpIntent.emergency,
          confidence: 0.95,
        );
      }
    }

    // Normal matching path
    final scored = _scoreAll(norm, entries);

    if (scored.isEmpty) {
      return NlpResult.unknown();
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final best = scored.first.key;
    final bestScore = scored.first.value;
    final secondScore = scored.length > 1 ? scored[1].value : 0;

    if (bestScore <= 0) {
      return NlpResult.unknown();
    }

    final confidence =
        (bestScore / (bestScore + secondScore + 5))
            .clamp(0.0, 1.0);

    return NlpResult(
      entry: best,
      topic: best.topic,
      condition: best.condition,
      category: best.category,
      intent: _intentFor(best),
      confidence: double.parse(
        confidence.toStringAsFixed(2),
      ),
    );
  }

  static NlpIntent _intentFor(
    KbEntry entry,
  ) {
    if (entry.entryId == 'S001') {
      return NlpIntent.emergency;
    }

    if (entry.category
        .toLowerCase()
        .contains('when to see')) {
      return NlpIntent.careGuidance;
    }

    final cat = entry.category.toLowerCase();

    if (cat.contains('medication')) {
      return NlpIntent.medication;
    }

    if (cat.contains('preventive')) {
      return NlpIntent.prevention;
    }

    if (cat.contains('diet')) {
      return NlpIntent.nutrition;
    }

    if (cat.contains('common conditions')) {
      return NlpIntent.symptomInfo;
    }

    return NlpIntent.wellness;
  }

  static KbEntry? _findById(
    List<KbEntry> entries,
    String id,
  ) {
    for (final e in entries) {
      if (e.entryId == id) {
        return e;
      }
    }

    return null;
  }

  static List<MapEntry<KbEntry, int>> _scoreAll(
    String normQuery,
    List<KbEntry> entries,
  ) {
    final out = <MapEntry<KbEntry, int>>[];

    for (final entry in entries) {
      int score = 0;

      for (final kw in entry.keywords) {
        final normKw = normalize(kw);

        if (normKw.isNotEmpty &&
            normQuery.contains(normKw)) {
          final words = normKw.split(' ').length;

          score += normKw.length + words * 4;
        }
      }

      if (score > 0) {
        out.add(
          MapEntry(entry, score),
        );
      }
    }

    return out;
  }

  static KbEntry? _bestByScore(
    String normQuery,
    List<KbEntry> entries,
  ) {
    final scored =
        _scoreAll(normQuery, entries);

    if (scored.isEmpty) {
      return null;
    }

    scored.sort(
      (a, b) =>
          b.value.compareTo(a.value),
    );

    return scored.first.key;
  }
}