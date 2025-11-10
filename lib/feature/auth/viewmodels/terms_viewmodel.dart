import 'package:flutter/material.dart';

class TermsViewModel with ChangeNotifier {
  bool _term01 = false;
  bool _term02 = false;
  bool _term03 = false;
  bool _term04 = false;

  bool get term01 => _term01;
  bool get term02 => _term02;
  bool get term03 => _term03;
  bool get term04 => _term04;

  bool get allTermsAgreed => _term01 && _term02 && _term03 && _term04;

  void termClick(int index) {
    if (index == 1) {
      _term01 = !_term01;
    } else if (index == 2) {
      _term02 = !_term02;
    } else if (index == 3) {
      _term03 = !_term03;
    } else if (index == 4) {
      _term04 = !_term04;
    }
    notifyListeners();
  }

  void termDisAgree() {
    _term01 = !_term01;
    _term02 = !_term02;
    _term03 = !_term03;
    _term04 = !_term04;
    notifyListeners();
  }
}
