#!/usr/bin/env python3
"""Attach the repository's stable, debug-only signing identity to the APK build."""
from pathlib import Path
import os
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: configure-stable-android-debug-signing.py <android-project-root>")

root = Path(sys.argv[1]).resolve()
gradle = root / "app" / "build.gradle"
if not gradle.is_file():
    raise SystemExit(f"Android Gradle file not found: {gradle}")

keystore = os.environ.get("TETRIOS_DEBUG_KEYSTORE")
if not keystore or not Path(keystore).is_file():
    raise SystemExit("TETRIOS_DEBUG_KEYSTORE is missing or does not exist")

source = gradle.read_text()
if "stableTetriosDebug" in source:
    print("Stable Tetrios debug signing is already configured.")
    raise SystemExit(0)

block = """
// Stable debug-only identity: allows successive CI APKs to update in place.
// Never reuse this debug key for a production/release build.
android {
    signingConfigs {
        stableTetriosDebug {
            storeFile file(System.getenv("TETRIOS_DEBUG_KEYSTORE"))
            storePassword System.getenv("TETRIOS_DEBUG_STORE_PASSWORD")
            keyAlias System.getenv("TETRIOS_DEBUG_KEY_ALIAS")
            keyPassword System.getenv("TETRIOS_DEBUG_KEY_PASSWORD")
        }
    }
    buildTypes {
        debug {
            signingConfig signingConfigs.stableTetriosDebug
        }
    }
}
"""
gradle.write_text(source.rstrip() + "\n" + block)
print("Configured stable Tetrios debug signing identity.")
