import 'danger_sign_handler.dart';

class SeizureHandler extends DangerSignHandler {
  @override
  bool handle(String text) {
    if (text.contains('seizure') ||
        text.contains('convulsion')) {
      return true;
    }

    return super.handle(text);
  }
}