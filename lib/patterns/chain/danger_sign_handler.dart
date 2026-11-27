abstract class DangerSignHandler {
  DangerSignHandler? nextHandler;

  void setNext(DangerSignHandler handler) {
    nextHandler = handler;
  }

  bool handle(String text) {
    if (nextHandler != null) {
      return nextHandler!.handle(text);
    }
    return false;
  }
}