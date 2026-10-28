import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android build defaults prevent plaintext and cloud-backup exposure',
      () async {
    final manifest = await File('android/app/src/main/AndroidManifest.xml')
        .readAsString();
    final extraction = await File(
      'android/app/src/main/res/xml/veldigo_data_extraction_rules.xml',
    ).readAsString();
    final activity = await File(
      'android/app/src/main/kotlin/com/brendigo/veldigo/MainActivity.kt',
    ).readAsString();
    final gradle = await File('android/app/build.gradle.kts').readAsString();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(manifest, contains('android:dataExtractionRules='));
    expect(extraction, contains('<cloud-backup>'));
    expect(extraction, contains('<device-transfer>'));
    expect(extraction, contains('<exclude domain="root" path="." />'));
    expect(activity, contains('WindowManager.LayoutParams.FLAG_SECURE'));
    expect(gradle, contains('minSdk = 24'));
  });
}
