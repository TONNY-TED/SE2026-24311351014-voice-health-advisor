import 'danger_sign_handler.dart';

class DifficultyBreathingHandler extends DangerSignHandler {
  @override
  bool handle(String text) {
    if (text.contains('difficulty breathing') ||
        text.contains('cannot breathe')) {
      return true;
    }

    return super.handle(text);
  }
}