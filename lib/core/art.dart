import 'package:flutter/services.dart';

/// Quali illustrazioni (da Antigravity) sono già nel pacchetto: finché una
/// manca, al suo posto si usa il disegno vettoriale.
class Art {
  static Set<String> _assets = {};

  static Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().toSet();
    } catch (_) {
      _assets = {};
    }
  }

  static bool has(String path) => _assets.contains(path);
}
