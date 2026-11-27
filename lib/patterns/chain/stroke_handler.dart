import 'danger_sign_handler.dart';

class StrokeHandler extends DangerSignHandler {
  @override
  bool handle(String text) {
    if (text.contains('face drooping') ||
        text.contains('slurred speech')) {
      return true;
    }

    return super.handle(text);
  }
}
