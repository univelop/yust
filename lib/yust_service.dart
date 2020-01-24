import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yust/yust_store.dart';

import 'models/yust_doc.dart';
import 'models/yust_doc_setup.dart';
import 'models/yust_exception.dart';
import 'models/yust_user.dart';
import 'yust.dart';

class YustService {
  final FirebaseAuth fireAuth = FirebaseAuth.instance;

  Future<void> signIn(
    BuildContext context,
    String email,
    String password, {
    String targetRouteName,
    dynamic targetRouteArguments,
  }) async {
    if (email == null || email == '') {
      throw YustException('Die E-Mail darf nicht leer sein.');
    }
    if (password == null || password == '') {
      throw YustException('Das Passwort darf nicht leer sein.');
    }
    await fireAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await waitForSignIn(
      Navigator.of(context),
      targetRouteName: targetRouteName,
      targetRouteArguments: targetRouteArguments,
    );
  }

  Future<void> signUp(
    BuildContext context,
    String firstName,
    String lastName,
    String email,
    String password,
    String passwordConfirmation, {
    YustGender gender,
    String targetRouteName,
    dynamic targetRouteArguments,
  }) async {
    if (firstName == null || firstName == '') {
      throw YustException('Der Vorname darf nicht leer sein.');
    }
    if (lastName == null || lastName == '') {
      throw YustException('Der Nachname darf nicht leer sein.');
    }
    if (password != passwordConfirmation) {
      throw YustException('Die Passwörter stimmen nicht überein.');
    }
    final fireUser = await fireAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = Yust.userSetup.newDoc() as YustUser
      ..email = email
      ..firstName = firstName
      ..lastName = lastName
      ..gender = gender
      ..id = fireUser.uid;

    await Yust.service.saveDoc<YustUser>(Yust.userSetup, user);

    await waitForSignIn(
      Navigator.of(context),
      targetRouteName: targetRouteName,
      targetRouteArguments: targetRouteArguments,
    );
  }

  Future<void> signOut(BuildContext context) async {
    await fireAuth.signOut();

    await fireAuth.onAuthStateChanged
        .firstWhere((FirebaseUser user) => user == null);

    Navigator.of(context).pushNamedAndRemoveUntil(
      Navigator.defaultRouteName,
      (_) => false,
    );
  }

  Future<void> waitForSignIn(
    NavigatorState navigatorState, {
    String targetRouteName = Navigator.defaultRouteName,
    dynamic targetRouteArguments,
  }) async {
    final completer = Completer<bool>();

    void Function() listener = () {
      switch (Yust.store.authState) {
        case AuthState.signedIn:
          completer.complete(true);
          break;
        case AuthState.signedOut:
          completer.complete(false);
          break;
        case AuthState.waiting:
          break;
      }
    };

    Yust.store.addListener(listener);

    bool successful = await completer.future;

    Yust.store.removeListener(listener);

    if (successful) {
      navigatorState.pushNamedAndRemoveUntil(
        targetRouteName,
        (_) => false,
        arguments: targetRouteArguments,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email == null || email == '') {
      throw YustException('Die E-Mail darf nicht leer sein.');
    }
    await fireAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> changeEmail(String email, String password) async {
    final user = await fireAuth.signInWithEmailAndPassword(
      email: Yust.store.currUser.email,
      password: password,
    );
    await user.updateEmail(email);
    Yust.store.setState(() {
      Yust.store.currUser.email = email;
    });
    Yust.service.saveDoc<YustUser>(Yust.userSetup, Yust.store.currUser);
  }

  Future<void> changePassword(String newPassword, String oldPassword) async {
    final user = await fireAuth.signInWithEmailAndPassword(
      email: Yust.store.currUser.email,
      password: oldPassword,
    );
    await user.updatePassword(newPassword);
  }

  T initDoc<T extends YustDoc>(YustDocSetup modelSetup, [T doc]) {
    if (doc == null) {
      doc = modelSetup.newDoc() as T;
    }
    doc.id = Firestore.instance
        .collection(modelSetup.collectionName)
        .document()
        .documentID;
    doc.createdAt = DateTime.now().toIso8601String();
    if (modelSetup.forEnvironment) {
      doc.envId = Yust.store.currUser.currEnvId;
    }
    if (modelSetup.forUser) {
      doc.userId = Yust.store.currUser.id;
    }
    if (modelSetup.onInit != null) {
      modelSetup.onInit(doc);
    }
    return doc;
  }

  ///[filterList] each entry represents a condition that has to be met.
  ///All of those conditions must be true for each returned entry.
  ///
  ///Consists at first of the column name followed by either 'ASC' or 'DESC'.
  ///Multiple of those entries can be repeated.
  Stream<List<T>> getDocs<T extends YustDoc>(YustDocSetup modelSetup,
      {List<List<dynamic>> filterList, List<String> orderByList}) {
    Query query = Firestore.instance.collection(modelSetup.collectionName);
    if (modelSetup.forEnvironment) {
      query = query.where('envId', isEqualTo: Yust.store.currUser.currEnvId);
    }
    if (modelSetup.forUser) {
      query = query.where('userId', isEqualTo: Yust.store.currUser.id);
    }
    query = _executeFilterList(query, filterList);
    query = _executeOrderByList(query, orderByList);
    return query.snapshots().map((snapshot) {
      // print('Get docs: ${modelSetup.collectionName}');
      return snapshot.documents.map((docSnapshot) {
        final doc = modelSetup.fromJson(docSnapshot.data) as T;
        if (modelSetup.onMigrate != null) {
          modelSetup.onMigrate(doc);
        }
        return doc;
      }).toList();
    });
  }

  Future<List<T>> getDocsOnce<T extends YustDoc>(YustDocSetup modelSetup,
      {List<List<dynamic>> filterList, List<String> orderByList}) {
    Query query = Firestore.instance.collection(modelSetup.collectionName);
    query = _executeStaticFilters(query, modelSetup);
    query = _executeFilterList(query, filterList);
    query = _executeOrderByList(query, orderByList);
    return query.getDocuments(source: Source.server).then((snapshot) {
      // print('Get docs once: ${modelSetup.collectionName}');
      return snapshot.documents.map((docSnapshot) {
        final doc = modelSetup.fromJson(docSnapshot.data) as T;
        if (modelSetup.onMigrate != null) {
          modelSetup.onMigrate(doc);
        }
        return doc;
      }).toList();
    });
  }

  Stream<T> getDoc<T extends YustDoc>(YustDocSetup modelSetup, String id) {
    return Firestore.instance
        .collection(modelSetup.collectionName)
        .document(id)
        .snapshots()
        .map((snapshot) {
      // print('Get doc: ${modelSetup.collectionName} $id');
      if (snapshot.data == null) return null;
      final doc = modelSetup.fromJson(snapshot.data) as T;
      if (modelSetup.onMigrate != null) {
        modelSetup.onMigrate(doc);
      }
      return doc;
    });
  }

  Future<T> getDocOnce<T extends YustDoc>(YustDocSetup modelSetup, String id) {
    return Firestore.instance
        .collection(modelSetup.collectionName)
        .document(id)
        .get(source: Source.server)
        .then((snapshot) {
      // print('Get doc: ${modelSetup.collectionName} $id');
      final doc = modelSetup.fromJson(snapshot.data) as T;
      if (modelSetup.onMigrate != null) {
        modelSetup.onMigrate(doc);
      }
      return doc;
    });
  }

  Stream<T> getFirstDoc<T extends YustDoc>(
      YustDocSetup modelSetup, List<List<dynamic>> filterList,
      {List<String> orderByList}) {
    Query query = Firestore.instance.collection(modelSetup.collectionName);
    if (modelSetup.forEnvironment) {
      query = query.where('envId', isEqualTo: Yust.store.currUser.currEnvId);
    }
    if (modelSetup.forUser) {
      query = query.where('userId', isEqualTo: Yust.store.currUser.id);
    }
    query = _executeFilterList(query, filterList);
    query = _executeOrderByList(query, orderByList);
    return query.snapshots().map<T>((snapshot) {
      if (snapshot.documents.length > 0) {
        final doc = modelSetup.fromJson(snapshot.documents[0].data) as T;
        if (modelSetup.onMigrate != null) {
          modelSetup.onMigrate(doc);
        }
        return doc;
      } else {
        return null;
      }
    });
  }

  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup modelSetup,
    T doc, {
    bool merge = true,
  }) async {
    var collection = Firestore.instance.collection(modelSetup.collectionName);
    if (doc.createdAt == null) {
      doc.createdAt = DateTime.now().toIso8601String();
    }
    if (doc.userId == null && modelSetup.forUser) {
      doc.userId = Yust.store.currUser.id;
    }
    if (doc.envId == null && modelSetup.forEnvironment) {
      doc.envId = Yust.store.currUser.currEnvId;
    }

    if (doc.id != null) {
      await collection.document(doc.id).setData(doc.toJson(), merge: merge);
    } else {
      var ref = await collection.add(doc.toJson());
      doc.id = ref.documentID;
      await ref.setData(doc.toJson());
    }
  }

  Future<void> deleteDocs<T extends YustDoc>(YustDocSetup modelSetup,
      {List<List<dynamic>> filterList}) async {
    final docs = await getDocsOnce(modelSetup, filterList: filterList);
    for (var doc in docs) {
      await deleteDoc(modelSetup, doc);
    }
  }

  Future<void> deleteDoc<T extends YustDoc>(
      YustDocSetup modelSetup, T doc) async {
    if (modelSetup.onDelete != null) {
      modelSetup.onDelete(doc);
    }
    var docRef = Firestore.instance
        .collection(modelSetup.collectionName)
        .document(doc.id);
    await docRef.delete();
  }

  void showAlert(BuildContext context, String title, String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              FlatButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Future<bool> showConfirmation(
      BuildContext context, String title, String action) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            actions: <Widget>[
              FlatButton(
                child: Text(action),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              FlatButton(
                child: Text("Abbrechen"),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
        });
  }

  Future<String> showTextFieldDialog(
      BuildContext context, String title, String placeholder, String action) {
    final controller = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: placeholder),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(action),
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
              ),
              FlatButton(
                child: Text("Abbrechen"),
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
              ),
            ],
          );
        });
  }

  ///Does not return null.
  String formatDate(String isoDate, {String format}) {
    if (isoDate == null) return '';

    var now = DateTime.parse(isoDate);
    var formatter = DateFormat(format ?? 'dd.MM.yyyy');
    return formatter.format(now);
  }

  ///Does not return null.
  String formatTime(String isoDate, {String format}) {
    if (isoDate == null) return '';

    var now = DateTime.parse(isoDate);
    var formatter = DateFormat(format ?? 'HH:mm');
    return formatter.format(now);
  }

  String randomString({int length = 8}) {
    final rnd = new Random();
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    var result = "";
    for (var i = 0; i < length; i++) {
      result += chars[rnd.nextInt(chars.length)];
    }
    return result;
  }

  Query _executeStaticFilters(Query query, YustDocSetup modelSetup) {
    if (modelSetup.forEnvironment) {
      query = query.where('envId', isEqualTo: Yust.store.currUser.currEnvId);
    }
    if (modelSetup.forUser) {
      query = query.where('userId', isEqualTo: Yust.store.currUser.id);
    }
    return query;
  }

  Query _executeFilterList(Query query, List<List<dynamic>> filterList) {
    if (filterList != null) {
      for (var filter in filterList) {
        switch (filter[1]) {
          case '==':
            query = query.where(filter[0], isEqualTo: filter[2]);
            break;
          case '<':
            query = query.where(filter[0], isLessThan: filter[2]);
            break;
          case '<=':
            query = query.where(filter[0], isLessThanOrEqualTo: filter[2]);
            break;
          case '>':
            query = query.where(filter[0], isGreaterThan: filter[2]);
            break;
          case '>=':
            query = query.where(filter[0], isGreaterThanOrEqualTo: filter[2]);
            break;
          case 'arrayContains':
            query = query.where(filter[0], arrayContains: filter[2]);
            break;
          case 'isNull':
            query = query.where(filter[0], isNull: filter[2]);
            break;
        }
      }
    }
    return query;
  }

  Query _executeOrderByList(Query query, List<String> orderByList) {
    if (orderByList != null) {
      orderByList.asMap().forEach((index, orderBy) {
        if (orderBy.toUpperCase() != 'DESC') {
          final desc = (index + 1 < orderByList.length &&
              orderByList[index + 1].toUpperCase() == 'DESC');
          query = query.orderBy(orderBy, descending: desc);
        }
      });
    }
    return query;
  }
}
