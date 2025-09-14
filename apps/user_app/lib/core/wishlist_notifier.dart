import 'package:flutter/foundation.dart';

class WishlistNotifier extends ChangeNotifier {
  WishlistNotifier._();
  static final WishlistNotifier instance = WishlistNotifier._();

  void emitChanged() {
    notifyListeners();
  }
}
