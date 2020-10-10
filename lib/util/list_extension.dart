extension ListExtension<T> on List<T> {
  T get firstOrNull => this.isEmpty ? null : this.first;
}
