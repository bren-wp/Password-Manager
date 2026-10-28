#!/usr/bin/env python3
"""Set Android app identity/privacy defaults on generated Flutter scaffolding."""
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
manifest = root / "android/app/src/main/AndroidManifest.xml"
gradle = root / "android/app/build.gradle.kts"
activity = root / "android/app/src/main/kotlin/com/brendigo/veldigo/MainActivity.kt"

if not (manifest.exists() and gradle.exists() and activity.exists()):
    raise SystemExit("Run Flutter bootstrap before configure_android.py")

namespace = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", namespace)
doc = ET.parse(manifest)
application = doc.getroot().find("application")
if application is None:
    raise SystemExit("Android manifest missing <application>")
application.set(f"{{{namespace}}}label", "Veldigo")
application.set(f"{{{namespace}}}allowBackup", "false")
application.set(f"{{{namespace}}}fullBackupContent", "false")
application.set(f"{{{namespace}}}usesCleartextTraffic", "false")
# Android 12+ device-to-device transfer may ignore allowBackup=false on
# some vendor builds. Explicitly exclude application files on both channels.
application.set(f"{{{namespace}}}dataExtractionRules",
                "@xml/veldigo_data_extraction_rules")
resource = root / "android/app/src/main/res/xml/veldigo_data_extraction_rules.xml"
resource.parent.mkdir(parents=True, exist_ok=True)
resource.write_text("""<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
  <cloud-backup>
    <exclude domain="root" path="." />
  </cloud-backup>
  <device-transfer>
    <exclude domain="root" path="." />
  </device-transfer>
</data-extraction-rules>
""", encoding="utf-8")
doc.write(manifest, encoding="utf-8", xml_declaration=True)

source = gradle.read_text(encoding="utf-8")
source = source.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
if "minSdk = 24" not in source:
    raise SystemExit("Unable to set minSdk 24")
gradle.write_text(source, encoding="utf-8")

activity.write_text(
    """package com.brendigo.veldigo

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
""",
    encoding="utf-8",
)
print("Veldigo identity, API 24, no OS backup and screenshot protection applied.")
