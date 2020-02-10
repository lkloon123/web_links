import 'dart:math';

import 'package:flutter/foundation.dart';

class LinkData {
  String id;
  String url;
  String title;

  LinkData({
    @required this.url,
    this.title,
  }) {
    this.id = _randomString();
  }

  String _randomString({int length = 20}) {
    var rand = Random();
    var codeUnits = List.generate(
      length,
      (index) => rand.nextInt(33) + 89,
    );

    return String.fromCharCodes(codeUnits);
  }
}
