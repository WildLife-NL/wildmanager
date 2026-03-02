import 'package:flutter/foundation.dart';

class FilterPanelController extends ChangeNotifier {
  FilterPanelController({bool initialOpen = false}) : _isOpen = initialOpen;

  bool _isOpen = false;
  bool get isOpen => _isOpen;

  set open(bool value) {
    if (_isOpen == value) return;
    _isOpen = value;
    notifyListeners();
  }

  void openPanel() => open = true;
  void closePanel() => open = false;
  void toggle() => open = !_isOpen;
}
