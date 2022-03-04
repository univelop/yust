extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
