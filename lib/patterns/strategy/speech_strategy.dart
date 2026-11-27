abstract class SpeechStrategy {
  String get languageCode;

  String processText(String text);
}
