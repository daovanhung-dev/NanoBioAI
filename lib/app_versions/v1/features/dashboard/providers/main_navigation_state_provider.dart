import 'package:flutter_riverpod/legacy.dart' show StateProvider;

/// Active tab of MainNavigationPage. Dashboard uses this to pause background
/// refresh while it is kept mounted off-screen by the page shell.
final mainNavigationIndexProvider = StateProvider<int>((ref) => 0);
