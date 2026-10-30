#!/usr/bin/env python3
"""Apply the hardened offline WebView configuration to the extracted APK project."""
# Exercised by the isolated Android WebView source-audit workflow.
# The audit also persists the patched starter archive on this feature branch.

from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: patch-android-webview.py <android-project-root>")

root = Path(sys.argv[1]).resolve()
gradle = root / "app" / "build.gradle"
activity = root / "app" / "src" / "main" / "java" / "com" / "maikllx" / "blockbuddies" / "MainActivity.java"

if not gradle.is_file() or not activity.is_file():
    raise SystemExit("Expected app/build.gradle and MainActivity.java were not found")

gradle_text = gradle.read_text()
dependency = 'implementation "androidx.webkit:webkit:1.15.0"'
if dependency not in gradle_text:
    if "dependencies {" in gradle_text:
        gradle_text = gradle_text.replace("dependencies {", "dependencies {\n    " + dependency, 1)
    else:
        gradle_text = gradle_text.rstrip() + "\n\ndependencies {\n    " + dependency + "\n}\n"
    gradle.write_text(gradle_text)

source = activity.read_text()
source = source.replace(
    "import android.webkit.WebViewClient;\n",
    "import androidx.webkit.WebViewAssetLoader;\n"
    "import androidx.webkit.WebViewClientCompat;\n"
    "import android.webkit.WebResourceRequest;\n"
    "import android.webkit.WebResourceResponse;\n"
    "import android.net.Uri;\n",
)

source = source.replace(
    "public class MainActivity extends Activity {\n\n    private WebView web;\n",
    """public class MainActivity extends Activity {

    private static final String APP_ASSET_URL =
            "https://appassets.androidplatform.net/assets/index.html";

    private WebView web;
    private WebViewAssetLoader assetLoader;
""",
)

source = source.replace(
    "        settings.setBuiltInZoomControls(false);\n\n        web.setWebViewClient(new WebViewClient());\n",
    """        settings.setBuiltInZoomControls(false);

        // All game files are bundled in APK assets. Do not expose file:// or
        // content:// access to page scripts; WebViewAssetLoader provides a
        // secure HTTPS origin for local HTML, modules, models, textures and audio.
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);

        assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        web.setWebViewClient(new LocalContentWebViewClient());
""",
)

source = source.replace(
    """        if (savedInstanceState != null) {
            web.restoreState(savedInstanceState);
        } else {
            web.loadUrl("file:///android_asset/index.html");
        }
""",
    """        if (savedInstanceState != null) {
            web.restoreState(savedInstanceState);
            String restoredUrl = web.getUrl();
            if (restoredUrl == null || !restoredUrl.startsWith(
                    "https://appassets.androidplatform.net/assets/")) {
                web.loadUrl(APP_ASSET_URL);
            }
        } else {
            web.loadUrl(APP_ASSET_URL);
        }
""",
)

source = source.replace(
    "    @Override\n    protected void onWindowFocusChanged(boolean hasFocus) {",
    "    @Override\n    public void onWindowFocusChanged(boolean hasFocus) {",
)

if "private final class LocalContentWebViewClient" not in source:
    anchor = "    @Override\n    protected void onWindowFocusChanged(boolean hasFocus) {"
    if anchor not in source:
        anchor = "    @Override\n    public void onWindowFocusChanged(boolean hasFocus) {"
    client = """    private final class LocalContentWebViewClient extends WebViewClientCompat {
        @Override
        public WebResourceResponse shouldInterceptRequest(
                WebView view, WebResourceRequest request) {
            return assetLoader.shouldInterceptRequest(request.getUrl());
        }

        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, String url) {
            return assetLoader.shouldInterceptRequest(Uri.parse(url));
        }
    }

"""
    if anchor not in source:
        raise SystemExit("Could not find safe insertion point for WebViewAssetLoader client")
    source = source.replace(anchor, client + anchor, 1)

required = [
    "androidx.webkit.WebViewAssetLoader",
    "androidx.webkit.WebViewClientCompat",
    'https://appassets.androidplatform.net/assets/index.html',
    "setAllowFileAccess(false)",
    "setAllowUniversalAccessFromFileURLs(false)",
    "assetLoader.shouldInterceptRequest(request.getUrl())",
]
missing = [item for item in required if item not in source]
if missing:
    raise SystemExit("WebView hardening patch incomplete: " + ", ".join(missing))

if "file:///android_asset/index.html" in source:
    raise SystemExit("Legacy file:// entry point remains in MainActivity.java")

activity.write_text(source)
print("Applied WebViewAssetLoader and disabled legacy file/content access.")
print("Pinned dependency: androidx.webkit:webkit:1.15.0 (minSdk 23 compatible).")
