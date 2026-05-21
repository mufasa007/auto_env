import 'package:flutter/animation.dart';

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 240);
  static const Curve curve = Curves.easeOutCubic;
}
