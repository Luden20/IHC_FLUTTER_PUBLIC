import 'login_action.dart';

class LoginOperation {
  LoginOperation(this.id, this.action);

  final int id;
  final LoginAction action;
  bool cancelled = false;
}
