import 'speech_strategy.dart';

class ChichewaSpeechStrategy implements SpeechStrategy {
  @override
  String get languageCode => 'ny-MW';

  @override
  String processText(String text) {
    return text.trim();
  }
}