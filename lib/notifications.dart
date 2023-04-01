import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class EmptyTokenFailure {}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;

  void requestPermissions({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    await _messaging.requestPermission(
      alert: alert,
      announcement: announcement,
      badge: badge,
      carPlay: carPlay,
      criticalAlert: criticalAlert,
      provisional: provisional,
      sound: sound,
    );
  }

  Future<Either<EmptyTokenFailure, String>> get token async {
    final token = await _messaging.getToken();
    if (token == null) {
      return Left(EmptyTokenFailure());
    } else {
      return Right(token);
    }
  }

  Future<NotificationSettings> get settings async => await _messaging.getNotificationSettings();

  void subscribeToTopic(String topic) {
    _messaging.subscribeToTopic(topic);
  }

  void onTokenRefresh(void Function(String) callback) {
    _onTokenRefreshSubscription = _messaging.onTokenRefresh.listen(callback);
  }

  // void onBackgroundMessage(Future<void> Function(RemoteMessage) callback) {
  //   FirebaseMessaging.onBackgroundMessage(callback);
  // }

  void onMessage(void Function(RemoteMessage) callback) {
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(callback);
  }

  void onMessageOpenedApp(void Function(RemoteMessage) callback) {
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(callback);
  }

  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _onTokenRefreshSubscription?.cancel();
  }
}
