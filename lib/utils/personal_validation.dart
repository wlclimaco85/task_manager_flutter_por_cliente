class EmailValidator {
  static String? validate(String? value) {
    return value==null ||  value.isEmpty ? "Email can't be empty" : null;
  }
}

class PasswordValidator {
  static String? validate(String? value) {
    return value==null ||value.isEmpty ? "Password can't be empty" : null;
  }
}