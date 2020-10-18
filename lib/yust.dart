library yust;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'yust_service.dart';
import 'yust_store.dart';

enum YustInputStyle {
  normal,
  outlineBorder,
}

class Yust {
  static YustStore store;
  static YustService service;
  static YustDocSetup<YustUser> userSetup;
  static bool useTimestamps = false;
  static String storageUrl;
  static String imagePlaceholderPath;

  static Future<void> initialize({
    YustStore store,
    YustService service,
    YustDocSetup userSetup,
    bool useTimestamps = false,
    String storageUrl,
    String imagePlaceholderPath,
  }) async {
    await Firebase.initializeApp();
    Yust.store = store ?? YustStore();
    Yust.service = service ?? YustService();
    Yust.userSetup = userSetup ?? YustUser.setup;
    Yust.useTimestamps = useTimestamps;
    Yust.storageUrl = storageUrl;
    Yust.imagePlaceholderPath = imagePlaceholderPath;

    if (kIsWeb) await FirebaseFirestore.instance.enablePersistence();

    PackageInfo packageInfo;
    if (!kIsWeb) packageInfo = await PackageInfo.fromPlatform();

    Yust.store.setState(() {
      Yust.store.authState = AuthState.waiting;
      Yust.store.packageInfo = packageInfo;
    });

    StreamSubscription<YustUser> userSubscription;

    ///Calls [Yust.store.setState] on each auth state change event.
    FirebaseAuth.instance.authStateChanges().listen((fireUser) async {
      if (userSubscription != null) userSubscription.cancel();
      if (fireUser != null) {
        userSubscription = Yust.service
            .getDoc<YustUser>(Yust.userSetup, fireUser.uid)
            .listen((user) async {
          if (user == null) {
            user = Yust.userSetup.newDoc()
              ..id = fireUser.uid
              ..email = fireUser.email;
            await Yust.service.saveDoc<YustUser>(Yust.userSetup, user);
          }

          Yust.store.setState(() {
            Yust.store.authState = AuthState.signedIn;
            Yust.store.currUser = user;
          });
        });
      } else {
        Yust.store.setState(() {
          Yust.store.authState = AuthState.signedOut;
          Yust.store.currUser = null;
        });
      }
    });
  }
}
