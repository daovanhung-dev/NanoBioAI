abstract class RegexConstants {
  static const email = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$';
  static const password = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}\$';
}
