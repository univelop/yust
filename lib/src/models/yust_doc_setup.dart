import 'yust_doc.dart';

/// The setup for a [YustDoc] is needed to read or save a document to the database.
class YustDocSetup<T extends YustDoc> {
  /// The name for the document collection.
  ///
  /// Example: An item should be saved in the collection 'items'.
  String collectionName;

  /// Callback to create a document out of a JSON map.
  T Function(Map<String, dynamic> json) fromJson;

  /// Callback to create a new document instance.
  T Function() newDoc;

  /// If true the `userId` of the [YustDoc] will be automatically set when saving.
  bool forUser;

  /// If true the [YustDoc] will be automatically saved in a subcollection under the tannant.
  bool forEnvironment;

  ///Should be set to true if this setup is used for an environment.
  bool isEnvironment;

  /// Should null values be removed, before writing the doc to the database.
  bool removeNullValues;

  /// Callback when initialising a new [YustDoc].
  void Function(T doc)? onInit;

  /// Callback when saving a [YustDoc].
  Future<void> Function(T doc)? onSave;

  YustDocSetup({
    required this.collectionName,
    required this.fromJson,
    required this.newDoc,
    this.forUser = false,
    this.forEnvironment = false,
    this.isEnvironment = false,
    this.onInit,
    this.onSave,
    this.removeNullValues = true,
  });
}