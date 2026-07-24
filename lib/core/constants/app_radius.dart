import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 9999;

  /// Matches the `rounded-comic` token from the mockup — used specifically
  /// for chapter/series cards, distinct from the default M3 radius.
  static const double comic = 20;

  static BorderRadius get comicRadius => BorderRadius.circular(comic);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}
