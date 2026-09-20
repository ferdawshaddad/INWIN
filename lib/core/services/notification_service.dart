import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/quote_request.dart';
import 'auth_service.dart';
import 'fcm_token_service.dart';
import 'request_service.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();
  static final _fcm = FirebaseMessaging.instance;
  static const _channel = AndroidNotificationChannel(
    'inwin_main',
    'INWIN',
    description: 'Notifications INWIN',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _local.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
      FirebaseMessaging.onMessage.listen(_handleForeground);
    } catch (error, stackTrace) {
      debugPrint('NotificationService.initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<String?> getToken() => _fcm.getToken();

  static Future<void> showTestNotification() async {
    await _local.show(
      0,
      'Test INWIN',
      'Ceci est une notification de test locale !',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> showRequestStatusNotification({
    required QuoteRequest request,
    required RequestStatus previousStatus,
  }) async {
    final title = _titleForStatus(request.status);
    if (title == null || request.status == previousStatus) return;

    await _local.show(
      request.id.hashCode,
      title,
      _bodyForStatus(request),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static void _handleForeground(RemoteMessage msg) {
    final n = msg.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static String? _titleForStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.quoted:
        return 'Nouveau devis disponible';
      case RequestStatus.reviewing:
        return 'Votre demande est en cours de revue';
      case RequestStatus.accepted:
        return 'Devis accepté';
      case RequestStatus.rejected:
        return 'Devis refusé';
      case RequestStatus.inProduction:
        return 'Votre commande est en production';
      case RequestStatus.delivered:
        return 'Votre commande a été livrée';
      case RequestStatus.cancelled:
        return 'Votre commande a été annulée';
      case RequestStatus.pending:
        return null;
    }
  }

  static String _bodyForStatus(QuoteRequest request) {
    final label =
        request.details['category'] ?? request.details['eventType'] ?? 'projet';
    if (request.status == RequestStatus.quoted && request.quotedPrice != null) {
      return '$label: devis de ${request.quotedPrice!.toStringAsFixed(0)} TND.';
    }
    return '$label: statut ${request.status.label.toLowerCase()}.';
  }
}

final notificationSyncProvider = Provider<NotificationSync>((ref) {
  final sync = NotificationSync(ref);
  ref.onDispose(sync.dispose);

  ref.listen<AsyncValue<AppUser?>>(currentUserProvider, (_, next) {
    sync.handleUser(next.valueOrNull);
  });

  sync.handleUser(ref.read(currentUserProvider).valueOrNull);
  return sync;
});

class NotificationSync {
  NotificationSync(this._ref);

  final Ref _ref;
  StreamSubscription<List<QuoteRequest>>? _requestSub;
  String? _activeUid;
  bool _primed = false;
  Map<String, RequestStatus> _knownStatuses = const {};

  Future<void> handleUser(AppUser? user) async {
    if (user == null || user.uid != _activeUid) {
      await _requestSub?.cancel();
      _requestSub = null;
      _activeUid = user?.uid;
      _knownStatuses = const {};
      _primed = false;
    }

    if (user == null) return;

    await _ref.read(fcmTokenSyncProvider).syncToken(user.uid);

    if (user.role != UserRole.customer || _requestSub != null) return;

    _requestSub = _ref
        .read(requestServiceProvider)
        .watchCustomerRequests(user.uid)
        .listen(_handleRequests);
  }

  Future<void> dispose() async {
    await _requestSub?.cancel();
  }

  void _handleRequests(List<QuoteRequest> requests) {
    final nextStatuses = <String, RequestStatus>{
      for (final request in requests) request.id: request.status,
    };

    if (!_primed) {
      _knownStatuses = nextStatuses;
      _primed = true;
      return;
    }

    for (final request in requests) {
      final previousStatus = _knownStatuses[request.id];
      if (previousStatus != null && previousStatus != request.status) {
        NotificationService.showRequestStatusNotification(
          request: request,
          previousStatus: previousStatus,
        );
      }
    }

    _knownStatuses = nextStatuses;
  }
}
