extension ListExtension<T> on List<T> {
  /// Returns the first element of the list if not empty.
  T? get firstOrNull => isEmpty ? null : first;
}
