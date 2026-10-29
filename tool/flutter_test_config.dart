import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

// Flutter's default golden font is Ahem: it draws squares for every letter
// and cannot verify Veldigo typography or real Material icon geometry.
// Load the app's actual bundled Roboto and MaterialIcons before capturing
// the 15 Android and 11 Windows demo screens. This runs ONLY for tool tests
// and adds no runtime network dependency or production code.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  await testMain();
}
