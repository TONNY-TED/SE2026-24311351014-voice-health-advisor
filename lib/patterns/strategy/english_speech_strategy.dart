import 'speech_strategy.dart';

class EnglishSpeechStrategy implements SpeechStrategy {
  @override
  String get languageCode => 'en-US';

  @override
  String processText(String text) {
    return text.trim();
  }
}