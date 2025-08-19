import 'yust_doc.dart';

/// The setup for a [YustDoc] is needed to read or save a document to the database.
class YustDocSetup<T extends YustDoc> {
  YustDocSetup({
    required this.collectionName,
    required this.fromJson,
    this.newDoc,
    this.envId,
    this.userId,
    this.hasAuthor = false,
    this.hasOwner = false,
    this.forEnvironment = false,
    this.isEnvironment = false,
    this.onInit,
    this.onSave,
    this.removeNullValues = true,
    this.trackModification = true,
    this.expiresAfter,
  });

  /// Creates a [YustDocSetup] for a collection group.
  factory YustDocSetup.forCollectionGroup({
    required String collectionName,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return YustDocSetup(
      collectionName: collectionName,
      fromJson: fromJson,
    );
  }

  /// The ID of the tenant to use.
  String? envId;

  /// The id of the YustUser authoring this database action
  String? userId;

  /// The name for the document collection.
  ///
  /// Example: An item should be saved in the collection 'items'.
  String collectionName;

  /// Callback to create a document out of a JSON map.
  T Function(Map<String, dynamic> json) fromJson;

  /// Callback to create a new document instance.
  T Function()? newDoc;

  ///Should be set to true if this setup is used for an environment.
  bool isEnvironment;

  /// If true the [YustDoc] will be automatically saved in a subcollection under the tenant.
  bool forEnvironment;

  /// If true the `userId` of the [YustDoc] will be automatically set when saving.
  ///
  /// Note that this, unlike [forEnvironment], doesn't set a filter for the userId
  bool hasOwner;

  /// If true the `createdBy` & `modifiedBy` of the [YustDoc] will be automatically set when saving.
  ///
  /// Disabling this makes sense, if the document isn't assigned to a user or generally not edited by users directly
  bool hasAuthor;

  /// Should null values be removed, before writing the doc to the database.
  bool removeNullValues;

  /// Should the database actions update the record specified by [hasAuthor] & [hasOwner].
  bool trackModification;

  /// If set, this will be used to set the [YustDoc.expiresAt] (TTL) of the document.
  /// Firestore will automatically delete the document after the specified duration.
  Duration? expiresAfter;

  /// Callback when initializing a new [YustDoc].
  void Function(T doc)? onInit;

  /// Callback when saving a [YustDoc].
  Future<void> Function(T doc)? onSave;

  @override
  int get hashCode => Object.hash(collectionName, envId, userId);

  @override
  bool operator ==(Object other) =>
      other is YustDocSetup &&
      collectionName == other.collectionName &&
      envId == other.envId &&
      userId == other.userId;
}
