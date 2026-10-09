// VoiceHealth Knowledge Base loader + search (24 entries from JSON).
// Loads assets/knowledge_base.json once, then keyword-matches queries.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// One knowledge-base article.
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

class KnowledgeBaseService {
  // App-wide disclaimer shown under every answer.
  static const String disclaimer =
      'General info only — not a diagnosis. See a qualified health worker if unsure.';

  // Load all 24 entries from the bundled JSON asset.
  static Future<List<KbEntry>> load() async {
    // Read the JSON file declared in pubspec assets.
    final raw = await rootBundle.loadString('assets/knowledge_base.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['entries'] as List? ?? [];
    return list
        .map((e) => KbEntry.fromJson(e as Map<String, dynamic>))
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
