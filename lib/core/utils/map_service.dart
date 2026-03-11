import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapService {
  /// Opens a Google Maps search for the given market name.
  /// Adds "gần đây" to find the nearest location.
  static Future<void> openMapForMarket(String marketName) async {
    final Uri url = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': '$marketName gần đây',
      },
    );

    try {
      // Force opening in an in-app browser (WebView)
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      debugPrint('Could not launch map: $e');
    }
  }
}
