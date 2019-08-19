import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/yust_doc.dart';
import 'models/yust_doc_setup.dart';
import 'models/yust_exception.dart';
import 'models/yust_user.dart';
import 'yust.dart';

class YustService {
  final FirebaseAuth fireAuth = FirebaseAuth.instance;

  Future<void> signIn(String email, String password) async {
    if (email == null || email == '') {
      throw YustException('Die E-Mail darf nicht leer sein.');
    }
    if (password == null || password == '') {
      throw YustException('Das Passwort darf nicht leer sein.');
    }
    await fireAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String firstName, String lastName, String email,
      String password, String passwordConfirmation) async {
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
    final user =
        YustUser(email: email, firstName: firstName, lastName: lastName)
          ..id = fireUser.uid;
    await Yust.service.saveDoc<YustUser>(YustUser.setup, user);
  }

  Future<void> signOut() async {
    await fireAuth.signOut();
  }

  T initDoc<T extends YustDoc>(YustDocSetup modelSetup, T doc) {
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

  Stream<T> getDoc<T extends YustDoc>(YustDocSetup modelSetup, String id) {
    return Firestore.instance
        .collection(modelSetup.collectionName)
        .document(id)
        .snapshots()
        .map((snapshot) {
      // print('Get doc: ${modelSetup.collectionName} $id');
      final doc = modelSetup.fromJson(snapshot.data) as T;
      if (modelSetup.onMigrate != null) {
        modelSetup.onMigrate(doc);
      }
      return doc;
    });
  }

  Stream<T> getFirstDoc<T extends YustDoc>(
      YustDocSetup modelSetup, List<List<dynamic>> filterList) {
    Query query = Firestore.instance.collection(modelSetup.collectionName);
    if (modelSetup.forEnvironment) {
      query = query.where('envId', isEqualTo: Yust.store.currUser.currEnvId);
    }
    if (modelSetup.forUser) {
      query = query.where('userId', isEqualTo: Yust.store.currUser.id);
    }
    query = _executeFilterList(query, filterList);
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
      YustDocSetup modelSetup, T doc) async {
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
      await collection.document(doc.id).setData(doc.toJson());
    } else {
      var ref = await collection.add(doc.toJson());
      doc.id = ref.documentID;
      await ref.setData(doc.toJson());
    }
  }

  Future<void> deleteDoc<T extends YustDoc>(
      YustDocSetup modelSetup, T doc) async {
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

  String formatDate(String isoDate) {
    var now = DateTime.parse(isoDate);
    var formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(now);
  }

  String formatTime(String isoDate) {
    var now = DateTime.parse(isoDate);
    var formatter = DateFormat('HH:mm');
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
        if (orderBy != 'DESC') {
          final desc = (index + 1 < orderByList.length &&
              orderByList[index + 1] == 'DESC');
          query = query.orderBy(orderBy, descending: desc);
        }
      });
    }
    return query;
  }
}
