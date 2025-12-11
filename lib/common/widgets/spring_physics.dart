import 'package:flutter/material.dart';

class CustomTabBarViewScrollPhysics extends ScrollPhysics {
  const CustomTabBarViewScrollPhysics({super.parent});

  @override
  CustomTabBarViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomTabBarViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => CustomSpringDescription();
}

class CustomSpringDescription implements SpringDescription {
  CustomSpringDescription._();

  static final _instance = CustomSpringDescription._();

  factory CustomSpringDescription() => _instance;

  @override
  final double mass = 0.5;

  @override
  final double stiffness = 100.0;

  @override
  final double damping = 15.556349186104045; // 2.2 * sqrt(50)

  @override
  double bounce = 0.0;

  @override
  Duration duration = const Duration(milliseconds: 500);
}
