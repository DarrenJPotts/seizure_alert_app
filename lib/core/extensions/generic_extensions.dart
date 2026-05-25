extension GenericExtensions<T> on T? {
  bool get isNull => this == null;
  bool get isNotNull => !isNull;
}
