import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Future<void> logTestEvent() async {
    await analytics.logEvent(
      name: 'test_event',
      parameters: {'success': 'true'},
    );
    print('Test event sent!');
  }
}

