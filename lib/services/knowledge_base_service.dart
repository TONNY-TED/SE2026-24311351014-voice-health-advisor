// VoiceHealth Knowledge Base loader + search (24 entries from JSON).

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// One knowledge-base article (matches the fields in knowledge_base.json).
class KbEntry {
  // Stable ID, e.g. W001.
  final String entryId;

  // Group, e.g. Wellness & lifestyle.
  final String category;

  // Short title, e.g. Sleep.
  final String topic;

  // Condition label, e.g. Malaria.
  final String condition;

  // Lowercase match phrases.
  final List<String> keywords;

  // Main info paragraph.
  final String content;

  // Practical tips list.
  final List<String> tips;

  // When to seek care.
  final String seeDoctorIf;

  // Listed source for verification.
  final String source;

  const KbEntry({
    required this.entryId,
    required this.category,
    required this.topic,
    required this.condition,
    required this.keywords,
    required this.content,
    required this.tips,
    required this.seeDoctorIf,
    required this.source,
  });

  // Build from JSON map.
  factory KbEntry.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        (v as List? ?? []).map((e) => e.toString()).toList();
    return KbEntry(
      entryId: json['entry_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      condition: json['condition']?.toString() ?? '',
      keywords: strList(json['keywords']).map((s) => s.toLowerCase()).toList(),
      content: json['content']?.toString() ?? '',
      tips: strList(json['tips']),
      seeDoctorIf: json['see_doctor_if']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }

  // Build from a Chichewa JSON map (keys end in "_ny").
  factory KbEntry.fromChichewaJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        (v as List? ?? []).map((e) => e.toString()).toList();
    return KbEntry(
      entryId: json['entry_id']?.toString() ?? '',
      category: 'Chichewa',
      topic: json['topic_ny']?.toString() ?? '',
      condition: json['condition_ny']?.toString() ?? '',
      keywords: strList(json['keywords_ny']).map((s) => s.toLowerCase()).toList(),
      content: json['content_ny']?.toString() ?? '',
      tips: strList(json['tips_ny']),
      seeDoctorIf: json['see_doctor_if_ny']?.toString() ?? '',
      source: 'Chichewa knowledge base (AI draft)',
    );
  }

  // Formatted answer shown in the advice box.
  String get formattedAdvice {
    // Keep it readable: content + first tips + see-doctor + source.
    final buffer = StringBuffer();
    buffer.writeln('$topic ($condition):');
    buffer.writeln(content);
    if (tips.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Tips:');
      for (var i = 0; i < tips.length && i < 3; i++) {
        buffer.writeln('- ${tips[i]}');
      }
    }
    if (seeDoctorIf.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('See a doctor if: $seeDoctorIf');
    }
    if (source.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Source: $source');
    }
    return buffer.toString();
  }
}

// Knowledge base service with static methods for backward compatibility.
class KnowledgeBaseService {
  // App-wide disclaimer shown under every answer.
  static const String disclaimer =
      'General info only — not a diagnosis. See a qualified health worker if unsure.';

  // Load all entries from the bundled JSON asset.
  static Future<List<KbEntry>> load() async {
    // Read the JSON file declared in pubspec assets.
    final raw = await rootBundle.loadString('assets/knowledge_base.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['entries'] as List? ?? [];
    return list
        .map((e) => KbEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Load the 50-entry Chichewa knowledge base (C001-C050).
  static Future<List<KbEntry>> loadChichewa() async {
    final raw = await rootBundle.loadString('assets/knowledge_base_ny.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['entries'] as List? ?? [];
    return list
        .map((e) => KbEntry.fromChichewaJson(e as Map<String, dynamic>))
        .toList();
  }

  // Score-based search: most keyword hits wins, longer phrases score more.
  static KbEntry? search(String query, List<KbEntry> entries) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return null;

    KbEntry? best;
    int bestScore = 0;

    for (final entry in entries) {
      int score = 0;
      for (final kw in entry.keywords) {
        // Exact phrase match scores by length (favours specific entries).
        if (kw.isNotEmpty && lower.contains(kw)) {
          score += kw.length + 2;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }
    return best;
  }
}

// ---------------------------------------------------------------------------
// Advanced knowledge base with rule-based search, synonyms and normalisation.
// ---------------------------------------------------------------------------

// A keyword rule, e.g. "knee + pain". Every group must match at least once.
class KbRule {
  final String id;
  final String pattern;
  final List<List<String>> groups;
  final List<String> entryIds;
  final String message;
  final bool emergency;
  final bool warning;

  KbRule({
    required this.id,
    required this.pattern,
    required this.groups,
    required this.entryIds,
    required this.message,
    required this.emergency,
    required this.warning,
  });

  factory KbRule.fromJson(Map<String, dynamic> j) => KbRule(
    id: j['id'] as String,
    pattern: j['pattern'] as String,
    groups: (j['keywords'] as List)
        .map((g) => List<String>.from(g as List))
        .toList(),
    entryIds: List<String>.from(j['entries'] as List),
    message: j['message'] as String,
    emergency: j['emergency'] as bool,
    warning: j['warning'] as bool,
  );
}

// Advanced knowledge base with rule-based search, synonyms and normalisation.
class KnowledgeBase {
  final List<KbEntry> entries;
  final List<KbRule> rules;
  final Map<String, List<String>> synonyms;
  final Map<String, KbEntry> _byId = {};

  KnowledgeBase._(this.entries, this.rules, this.synonyms) {
    for (final e in entries) {
      _byId[e.entryId] = e;
    }
  }

  /// Loads assets/knowledge_base.json and assets/keyword_rules.json.
  static Future<KnowledgeBase> load() async {
    final entriesJson = jsonDecode(
        await rootBundle.loadString('assets/knowledge_base.json')) as List;
    final rulesJson = jsonDecode(
            await rootBundle.loadString('assets/keyword_rules.json')) as Map<String, dynamic>;

    final entries = entriesJson
        .map((e) => KbEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final rules = (rulesJson['rules'] as List)
        .map((r) => KbRule.fromJson(r as Map<String, dynamic>))
        .toList();
    final synonyms = (rulesJson['synonyms'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, List<String>.from(v as List)));

    return KnowledgeBase._(entries, rules, synonyms);
  }

  KbEntry? entryById(String id) => _byId[id];

  /// Finds matching entries for free text such as "my knee hurts on stairs".
  SearchResult search(String query, {int maxRules = 3, int maxEntries = 5}) {
    // Normalise user input: lowercases, removes punctuation, appends synonyms.
    String normalise(String input) {
      var t = input.toLowerCase().replaceAll('\u2019', "'");
      t = t.replaceAll(RegExp(r"\bcan'?t\b"), 'cannot').replaceAll('can not', 'cannot');
      t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
      t = ' ${t.replaceAll(RegExp(r'\s+'), ' ').trim()} ';
      return t;
    }

    final text = normalise(query);

    // Terms starting with "=" or with 3 letters or fewer match whole words.
    // Other terms match the start of a word (so "swell" matches "swelling").
    bool termMatches(String term, String textInput) {
      var t = term;
      var exact = false;
      if (t.startsWith('=')) {
        exact = true;
        t = t.substring(1);
      }
      if (t.length <= 3) exact = true;
      final pattern =
          exact ? '\\b${RegExp.escape(t)}(s|ed|es)?\\b' : '\\b${RegExp.escape(t)}';
      return RegExp(pattern).hasMatch(textInput);
    }

    // 1) Keyword rules: every group needs at least one matching term.
    final matched = <MapEntry<int, KbRule>>[];
    for (var i = 0; i < rules.length; i++) {
      final r = rules[i];
      final ok = r.groups.every((g) => g.any((term) => termMatches(term, text)));
      if (ok) matched.add(MapEntry(i, r));
    }
    // Most specific rule first (more groups), then file order.
    matched.sort((a, b) {
      final byGroups = b.value.groups.length.compareTo(a.value.groups.length);
      return byGroups != 0 ? byGroups : a.key.compareTo(b.key);
    });

    if (matched.isNotEmpty) {
      final top = matched.take(maxRules).map((m) => m.value).toList();
      final ids = <String>[];
      for (final r in top) {
        for (final id in r.entryIds) {
          if (!ids.contains(id)) ids.add(id);
        }
      }
      final found = ids
          .take(maxEntries)
          .map((id) => _byId[id])
          .whereType<KbEntry>()
          .toList();
      return SearchResult(
        entries: found,
        messages: top.map((r) => r.message).toList(),
        emergency: top.any((r) => r.emergency),
        fromRules: true,
        ruleIds: top.map((r) => r.id).toList(),
      );
    }

    // 2) Fallback: score each entry by how many of its own keywords appear.
    final scored = <MapEntry<int, KbEntry>>[];
    for (final e in entries) {
      var score = 0;
      for (final k in [...e.keywords, e.topic.toLowerCase()]) {
        final kk = k.toLowerCase().trim();
        if (kk.isNotEmpty && termMatches(kk, text)) {
          score += kk.split(' ').length;
        }
      }
      if (score > 0) scored.add(MapEntry(score, e));
    }
    scored.sort((a, b) => b.key.compareTo(a.key));

    return SearchResult(
      entries: scored.take(maxEntries).map((s) => s.value).toList(),
      messages: const [],
      emergency: false,
      fromRules: false,
      ruleIds: const [],
    );
  }
}

// Search result containing matched entries, messages from rules,
// and flags for emergency/warning conditions.
class SearchResult {
  final List<KbEntry> entries;
  final List<String> messages;
  final bool emergency;
  final bool fromRules;
  final List<String> ruleIds;

  SearchResult({
    required this.entries,
    required this.messages,
    required this.emergency,
    required this.fromRules,
    required this.ruleIds,
  });
}