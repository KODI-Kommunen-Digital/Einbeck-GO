import 'package:bloc/bloc.dart';
import 'package:heidi/src/data/repository/user_repository.dart';
import 'package:heidi/src/presentation/main/login/signup/cubit/signup_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(const SignUpState.loading());

  Future<bool> onRegister({
    required String firstname,
    required String lastname,
    required String username,
    required String password,
    required String confirmPassword,
    required String email,
    required String role,
  }) async {
    return await UserRepository.register(
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        email: email,
        firstname: firstname,
        lastname: lastname,
        role: "3");
  }

  ///Event forgot password
  Future<bool> onForgotPassword(String username) async {
    return await UserRepository.forgotPassword(username: username);
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Password is required.";
    }

    if (password.length < 8) {
      return "Password must be at least 8 characters long.";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least one uppercase letter.";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least one lowercase letter.";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least one digit.";
    }

    if (!RegExp(r'[@#\$%&]').hasMatch(password)) {
      return "At least one of the following special characters required.";
    }

    if (RegExp(r'[^a-zA-Z0-9@#\$%&]').hasMatch(password)) {
      return "Password contains invalid characters.";
    }

    return null; // Password is valid.
  }
}
