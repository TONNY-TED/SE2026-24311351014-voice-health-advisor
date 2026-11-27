import 'danger_sign_handler.dart';

class BleedingHandler extends DangerSignHandler {
  @override
  bool handle(String text) {
    if (text.contains('severe bleeding')) {
      return true;
    }

    return super.handle(text);
  }
}