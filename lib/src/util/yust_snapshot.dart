import '../models/yust_doc.dart';

enum SnapshotState { noData, loading, loaded, error }

class YustSnapshot<T extends YustDoc> {
  T? document;

  SnapshotState state;

  YustSnapshot({this.document, this.state = SnapshotState.loading});

  static Stream<YustSnapshot<V>> mapStream<V extends YustDoc>(
      Stream<V?> stream) {
    return stream.map((document) => YustSnapshot(
        document: document,
        state: document == null ? SnapshotState.error : SnapshotState.loaded));
  }

  static Stream<YustSnapshot<V>> emptyStream<V extends YustDoc>() =>
      Stream.fromIterable([YustSnapshot<V>(state: SnapshotState.noData)]);
}
