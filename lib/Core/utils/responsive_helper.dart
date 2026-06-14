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

  static double cardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isTablet(context)) return width / 4 - 24;
    return width / 2 - 24;
  }

  static double canvasSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (isTablet(context)) {
      return size.shortestSide * 0.55;
    }
    return size.width * 0.85;
  }

  static double characterCardSize(BuildContext context) {
    if (isTablet(context)) return 120;
    return 90;
  }

  static double characterFontSize(BuildContext context) {
    if (isTablet(context)) return 48;
    return 36;
  }

  static double guideCharFontSize(BuildContext context) {
    if (isTablet(context)) return 240;
    return 180;
  }

  static int gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 6;
    if (width > 600) return 4;
    return 4;
  }
}
