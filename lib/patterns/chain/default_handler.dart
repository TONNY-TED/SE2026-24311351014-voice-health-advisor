import 'danger_sign_handler.dart';

class DefaultHandler extends DangerSignHandler {
  @override
  bool handle(String text) {
    return false;
  }
}
