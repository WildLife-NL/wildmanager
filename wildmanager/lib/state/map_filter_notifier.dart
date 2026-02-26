import 'package:flutter/foundation.dart';

import 'filter_state.dart';

class MapFilterNotifier extends ChangeNotifier {
  MapFilterNotifier() : _state = FilterState.defaults;

  FilterState _state;
  FilterState get state => _state;

  void apply(FilterState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  void reset() {
    if (_state == FilterState.defaults) return;
    _state = FilterState.defaults;
    notifyListeners();
  }
}
