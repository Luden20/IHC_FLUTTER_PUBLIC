
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import '../components/general/toast.dart';
import '../firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
void firebaseFMCListener (RemoteMessage message, dynamic messengerKey, dynamic navigatorKey,FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) {
  final ctx = messengerKey.currentContext ?? navigatorKey.currentContext;
  final title = message.notification?.title ?? 'Nuevo mensaje';
  final body = message.notification?.body ?? '';
  if (ctx != null) {
    final composedMessage = body.isNotEmpty ? '$title: $body' : title;
    personalizedToast(
      ctx,
      composedMessage,
      messengerState: messengerKey.currentState,
    );

    showSimpleNotification(title,body,flutterLocalNotificationsPlugin);
  } else {
    if (kDebugMode) {
      debugPrint('⚠️ No hay Scaffold activo');
    }
  }
}
Future<void> showSimpleNotification(String title, String body ,FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin  ) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails('default_channel', 'Notificaciones',
      channelDescription: 'Canal de notificaciones simples',
      importance: Importance.max,
      priority: Priority.high);

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}
