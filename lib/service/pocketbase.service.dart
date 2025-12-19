import 'dart:ffi';

import 'package:appihv/components/general/toast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PBService {
  static late PocketBase _pb;
  static SharedPreferences? _prefs ;
  static const String baseUrl = 'https://ihcapp-production.up.railway.app';
  static Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }
  static Future<void> init() async {
    await _initPrefs();

    final store = AsyncAuthStore(
      save: (String data) {
        return _prefs!.setString('pb_auth', data);
      },
      initial: _prefs!.getString('pb_auth'),
    );
    _pb = PocketBase(baseUrl, authStore: store);
    try{
      final authData = await _pb.collection('users').authRefresh();

    }
    catch(e){
      print(e);
    }

  }
  static get notificationsEnable{
    if(_prefs==null){
       _initPrefs().ignore();
       return false;
    }
    return _prefs!.getBool('notifications')??false;
  }
  static  set notificationsEnable(bool value)  {
    _prefs!.setBool('notifications', value);
  }
  static PocketBase get client => _pb;
  static RecordModel? get actualUser => client.authStore.record;
  static bool get isLoggedIn => actualUser != null;
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_auth');
    client.authStore.clear();
  }

  static Future<void> loginActions() async {
    if (!isLoggedIn) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (kDebugMode) {
        debugPrint('token generado: $token');
      }
      if (token == null || token.isEmpty) {
        return;
      }

      if (actualUser == null) {
        return;
      }

      final List<String> currentTokens = [];
      for (final sns in actualUser!.getListValue("sns")) {
        if(token!=sns){
          currentTokens.add(sns);
        }
      }
      currentTokens.add(token);
      await client.collection('users').update(actualUser!.id, body: {'sns': currentTokens},);
      if (kDebugMode) {
        debugPrint('token count synced: ${currentTokens.length}');
      }
    } catch (error, stackTrace) {
      debugPrint('PBService.loginActions error: $error\n$stackTrace');
    }
  }

  static String fileUrl(RecordModel record, String fileName) =>
      '$baseUrl/api/files/${record.collectionId}/${record.id}/$fileName';
  static String fileThumbnailUrl(String baseUrl, int width, int? height) {
    return '$baseUrl?thumb=${width}x$height';
  }
}
