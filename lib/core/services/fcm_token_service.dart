import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// Keeps the FCM token in Firestore in sync whenever it refreshes.
final fcmTokenSyncProvider = Provider<FcmTokenSync>((ref) {
  return FcmTokenSync(ref);
});

class FcmTokenSync {
  final Ref _ref;
  FcmTokenSync(this._ref);

  Future<void> syncToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _ref.read(authServiceProvider).updateFcmToken(uid, token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _ref.read(authServiceProvider).updateFcmToken(uid, newToken);
      });
    } catch (error, stackTrace) {
      debugPrint('FcmTokenSync.syncToken failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
