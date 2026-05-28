import 'package:flutter/widgets.dart';

import '../constants/app_dimensions.dart';

class DeviceUtils {
  DeviceUtils._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.tabletMinWidth;

  static bool isPhone(BuildContext context) => !isTablet(context);

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.desktopMinWidth;
}
