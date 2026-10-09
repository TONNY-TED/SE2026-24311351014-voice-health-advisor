// Healthcare Knowledge Base (Week 3) + Recommendation Engine (Week 4).
// Stores 6 topics and finds the best match using keyword detection.

class HealthTopic {
  // Short ID used in code, e.g. 'sleep'.
  final String id;

  // Display title, e.g. 'Sleep'.
  final String title;

  // Keywords that trigger this topic, all lowercase.
  final List<String> keywords;

  // Main guidance shown to the user.
  final String advice;

  const HealthTopic({
    required this.id,
    required this.title,
    required this.keywords,
    required this.advice,
  });
}

class HealthService {
  // All 6 knowledge-base entries in one place (easy for UML + report).
  static const List<HealthTopic> topics = [
    HealthTopic(
      id: 'sleep',
      title: 'Sleep',
      keywords: ['sleep', 'insomnia', 'tired', 'rest', 'bed'],
      advice:
          'Maintain regular sleeping hours (7-9h). Avoid caffeine before bed and keep your room dark and quiet.',
    ),
    HealthTopic(
      id: 'hydration',
      title: 'Hydration',
      keywords: ['water', 'hydration', 'drink', 'thirst', 'dehydrated'],
      advice:
          'Drink at least 8 glasses of water daily. Carry a bottle and sip regularly, more when hot or active.',
    ),
    HealthTopic(
      id: 'exercise',
      title: 'Exercise',
      keywords: ['exercise', 'workout', 'gym', 'run', 'walk', 'sport'],
      advice:
          'Exercise at least 30 minutes daily. Mix walking, strength and stretching. Start small and stay consistent.',
    ),
    HealthTopic(
      id: 'diet',
      title: 'Diet',
      keywords: ['diet', 'food', 'eat', 'nutrition', 'meal', 'fruit', 'vegetable'],
      advice:
          'Eat balanced meals: half vegetables/fruits, whole grains, lean protein. Limit sugar, salt and fried food.',
    ),
    HealthTopic(
      id: 'stress',
      title: 'Stress',
      keywords: ['stress', 'anxiety', 'worry', 'mental', 'pressure', 'calm'],
      advice:
          'Manage stress with deep breathing, short breaks and walks. Sleep well and talk to someone you trust.',
    ),
    HealthTopic(
      id: 'lifestyle',
      title: 'Healthy Lifestyle',
      keywords: ['lifestyle', 'healthy', 'habit', 'smoke', 'alcohol', 'hygiene'],
      advice:
          'Build healthy habits: no smoking, limit alcohol, wash hands, keep checkups and stay socially active.',
    ),
  ];

  // Recommendation engine: Question -> keyword detection -> topic -> guidance.
  // Returns the matched topic, or null when nothing matches.
  static HealthTopic? findForQuery(String query) {
    // Lowercase so "Sleep" and "sleep" both match.
    final lower = query.toLowerCase();

    // Check each topic's keywords in order.
    for (final topic in topics) {
      for (final keyword in topic.keywords) {
        if (lower.contains(keyword)) {
          return topic;
        }
      }
    }
    return null;
  }

  // Helper for UI chips: just the 6 titles.
  static List<String> get titles => topics.map((t) => t.title).toList();
}
