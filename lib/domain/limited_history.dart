class LimitedHistory {
  final int limit;
  final List<String> _items = [];

  LimitedHistory({required this.limit});

  List<String> get items => List.unmodifiable(_items);

  void add(String value) {
    _items.insert(0, value);
    while (_items.length > limit) {
      _items.removeLast();
    }
  }

  void clear() {
    _items.clear();
  }
}
