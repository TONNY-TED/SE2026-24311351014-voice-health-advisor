// NLP logic (Step 5): topic, condition and intent extraction.
// Rule-based, no extra packages: normalize -> keyword phrase match -> scored entry.

import 'knowledge_base_service.dart';

// Intent = what the user wants (used for UML + report).
enum NlpIntent {
  emergency, // needs urgent care now
  symptomInfo, // "i have fever / cough"
  prevention, // "prevent malaria / wash hands"
  nutrition, // diet / food questions
  medication, // paracetamol / antibiotics / ORS
  careGuidance, // "when to see doctor / fever warning"
  wellness, // sleep / stress / exercise / water
  unknown, // no match
}

// Result of parsing one user query.
class NlpResult {
  // Best matching KB entry (null when nothing matches).
  final KbEntry? entry;

  // Extracted topic, e.g. Malaria.
  final String topic;

  // Extracted condition, e.g. Malaria.
  final String condition;

  // KB category, e.g. Preventive care.
  final String category;

  // Classified intent.
  final NlpIntent intent;

  // 0.0 - 1.0 confidence from score gap.
  final double confidence;

  // True when this is an emergency (drives warning UI).
  bool get isEmergency => intent == NlpIntent.emergency;

  const NlpResult({
    required this.entry,
    required this.topic,
    required this.condition,
    required this.category,
    required this.intent,
    required this.confidence,
  });

  // Fallback when nothing matches.
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
  // Emergency phrases always win, even with low keyword score (safety first).
  static const List<String> _emergencyPatterns = [
    'chest pain',
    'cannot breathe',
    'difficulty breathing',
    'unconscious',
    'severe bleeding',
    'seizure',
    'face drooping',
    'slurred speech',
    'thoughts of harming',
  ];

  // Lowercase, strip punctuation, collapse spaces for matching.
  static String normalize(String input) {
    var s = input.toLowerCase();
    // Keep only letters/numbers/spaces.
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    // Collapse repeated spaces.
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  // Parse query into topic + condition + intent using the 24-entry base.
  static NlpResult parse(String query, List<KbEntry> entries) {
    final norm = normalize(query);
    if (norm.isEmpty || entries.isEmpty) return NlpResult.unknown();

    // Emergency override: direct phrase hit forces S001.
    for (final pattern in _emergencyPatterns) {
      if (norm.contains(pattern)) {
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
    }

    // Normal path: best scoring entry by keyword phrase hits.
    final scored = _scoreAll(norm, entries);
    if (scored.isEmpty) return NlpResult.unknown();

    // Sort high -> low, confidence = gap between 1st and 2nd.
    scored.sort((a, b) => b.value.compareTo(a.value));
    final best = scored.first.key;
    final bestScore = scored.first.value;
    final secondScore = scored.length > 1 ? scored[1].value : 0;
    if (bestScore <= 0) return NlpResult.unknown();

    // Confidence in 0..1 from how clearly the winner beats runner-up.
    final confidence =
        (bestScore / (bestScore + secondScore + 5)).clamp(0.0, 1.0);

    return NlpResult(
      entry: best,
      topic: best.topic,
      condition: best.condition,
      category: best.category,
      intent: _intentFor(best),
      confidence: double.parse(confidence.toStringAsFixed(2)),
    );
  }

  // Map a KB entry to an intent from its category/ID.
  static NlpIntent _intentFor(KbEntry entry) {
    // Urgent-care entries are emergencies or care guidance.
    if (entry.entryId == 'S001') return NlpIntent.emergency;
    if (entry.category.toLowerCase().contains('when to see')) {
      return NlpIntent.careGuidance;
    }
    final cat = entry.category.toLowerCase();
    if (cat.contains('medication')) return NlpIntent.medication;
    if (cat.contains('preventive')) return NlpIntent.prevention;
    if (cat.contains('diet')) return NlpIntent.nutrition;
    if (cat.contains('common conditions')) return NlpIntent.symptomInfo;
    return NlpIntent.wellness;
  }

  // Find entry by ID (used for emergency S001).
  static KbEntry? _findById(List<KbEntry> entries, String id) {
    for (final e in entries) {
      if (e.entryId == id) return e;
    }
    return null;
  }

  // Score every entry: each hit adds keyword length + phrase bonus.
  static List<MapEntry<KbEntry, int>> _scoreAll(
      String normQuery, List<KbEntry> entries) {
    final out = <MapEntry<KbEntry, int>>[];
    for (final entry in entries) {
      int score = 0;
      for (final kw in entry.keywords) {
        final normKw = normalize(kw);
        if (normKw.isNotEmpty && normQuery.contains(normKw)) {
          // Longer phrases (e.g. "high blood pressure") beat single words.
          final words = normKw.split(' ').length;
          score += normKw.length + words * 4;
        }
      }
      if (score > 0) out.add(MapEntry(entry, score));
    }
    return out;
  }

  // Fallback best entry without intent (used when S001 missing).
  static KbEntry? _bestByScore(String normQuery, List<KbEntry> entries) {
    final scored = _scoreAll(normQuery, entries);
    if (scored.isEmpty) return null;
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.first.key;
  }
}
