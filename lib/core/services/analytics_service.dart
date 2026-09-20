import 'package:flutter/foundation.dart';

/// Thin wrapper around analytics events.
/// Swap the body of [_log] to connect Firebase Analytics, Mixpanel, etc.
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  void _log(String event, [Map<String, Object>? params]) {
    if (kDebugMode) {
      debugPrint('[Analytics] $event ${params ?? ''}');
    }
    // TODO: FirebaseAnalytics.instance.logEvent(name: event, parameters: params);
  }

  void requestSubmitted(String type, String category) =>
      _log('request_submitted', {'type': type, 'category': category});

  void quoteViewed(String requestId) =>
      _log('quote_viewed', {'request_id': requestId});

  void quoteAccepted(String requestId, double amount) =>
      _log('quote_accepted', {'request_id': requestId, 'amount': amount});

  void quoteRejected(String requestId) =>
      _log('quote_rejected', {'request_id': requestId});

  void messageSent(String requestId, bool isAdmin) =>
      _log('message_sent', {'request_id': requestId, 'is_admin': isAdmin});

  void screenView(String screenName) =>
      _log('screen_view', {'screen_name': screenName});
}
