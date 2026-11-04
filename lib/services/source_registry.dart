// Source registry: real authorities behind the knowledge base.
// Loads assets/health_sources.json and resolves entry source strings
// like "WHO - Malaria fact sheet" to a clickable authority URL.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// One authority: WHO, CDC, MedlinePlus, NHS, OpenFDA, ICD-11.
class HealthSource {
  // Short id: who, cdc, medlineplus, nhs, openfda, icd11.
  final String id;

  // Display name.
  final String name;

  // Homepage / search URL.
  final String url;

  // Which entries to verify against this source.
  final String useFor;

  // How to turn a page into a KB entry.
  final String how;

  // Optional JSON API endpoint (OpenFDA, MedlinePlus Connect, ICD-11).
  final String? api;

  const HealthSource({
    required this.id,
    required this.name,
    required this.url,
    required this.useFor,
    required this.how,
    this.api,
  });

  // Build from JSON map.
  factory HealthSource.fromJson(Map<String, dynamic> json) => HealthSource(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        useFor: json['use_for']?.toString() ?? '',
        how: json['how']?.toString() ?? '',
        api: json['api']?.toString(),
      );
}

class SourceRegistry {
  // Load all 6 authorities from the bundled JSON asset.
  static Future<List<HealthSource>> load() async {
    // Read the JSON file declared in pubspec assets.
    final raw = await rootBundle.loadString('assets/health_sources.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['sources'] as List? ?? [];
    return list
        .map((e) => HealthSource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Resolve an entry source string ("WHO - ...") to its authority URL.
  // Returns the authority homepage so every answer is verifiable.
  static String resolveUrl(String source) {
    final s = source.toLowerCase();
    if (s.startsWith('who')) return 'https://www.who.int/news-room/fact-sheets';
    if (s.startsWith('cdc')) return 'https://www.cdc.gov';
    if (s.startsWith('medlineplus')) return 'https://medlineplus.gov';
    if (s.startsWith('nhs')) return 'https://www.nhs.uk/conditions';
    if (s.startsWith('openfda')) return 'https://open.fda.gov';
    if (s.contains('ministry of health')) {
      return 'https://www.who.int/news-room/fact-sheets';
    }
    return 'https://www.who.int/news-room/fact-sheets';
  }
}
