import 'package:flutter/material.dart';

enum DeviceType { phone, tablet }

class ResponsiveHelper {
  ResponsiveHelper._();

  static DeviceType getDeviceType(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600 ? DeviceType.tablet : DeviceType.phone;
  }

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static double canvasSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (isTablet(context)) {
      return size.shortestSide * 0.55;
    }
    return size.width * 0.85;
  }
}
