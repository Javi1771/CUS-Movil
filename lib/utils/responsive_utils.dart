import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 360 && width < 768;
  }

  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 768;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    if (width < 360) {
      return baseSize * 0.9;
    } else if (width > 768) {
      return baseSize * 1.1;
    }
    return baseSize;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) {
      return const EdgeInsets.all(16);
    } else if (width > 768) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(20);
  }

  static double getResponsiveCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) {
      return width - 32; // 16px padding on each side
    } else if (width > 768) {
      return width * 0.8; // 80% of screen width for larger screens
    }
    return width - 40; // 20px padding on each side
  }

  static int getResponsiveMaxLines(BuildContext context, int baseLines) {
    if (isSmallScreen(context)) {
      return baseLines - 1 > 0 ? baseLines - 1 : 1;
    }
    return baseLines;
  }

  static Widget buildResponsiveText(
    String text, {
    required TextStyle style,
    required BuildContext context,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.start,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      style: style.copyWith(
        fontSize: getResponsiveFontSize(context, style.fontSize ?? 14),
      ),
      maxLines: getResponsiveMaxLines(context, maxLines),
      textAlign: textAlign,
      overflow: overflow,
    );
  }

  static Widget buildSafeContainer({
    required Widget child,
    required BuildContext context,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxDecoration? decoration,
    double? width,
    double? height,
  }) {
    return Container(
      width: width ?? getResponsiveCardWidth(context),
      height: height,
      padding: padding ?? getResponsivePadding(context),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }

  static Widget buildFlexibleRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        if (child is Text) {
          return Flexible(child: child);
        } else if (child is Container && child.child is Text) {
          return Flexible(child: child);
        }
        return child;
      }).toList(),
    );
  }

  static Widget buildSafeColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  static Widget buildConstrainedBox({
    required Widget child,
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? getScreenWidth(context),
        maxHeight: maxHeight ?? double.infinity,
        minWidth: minWidth ?? 0,
        minHeight: minHeight ?? 0,
      ),
      child: child,
    );
  }

  static Widget buildOverflowSafeWidget({
    required Widget child,
    required BuildContext context,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth * 2, // Allow up to 2x width
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// Extension methods for easier usage
extension ResponsiveContext on BuildContext {
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);
  bool get isSmallScreen => ResponsiveUtils.isSmallScreen(this);
  bool get isMediumScreen => ResponsiveUtils.isMediumScreen(this);
  bool get isLargeScreen => ResponsiveUtils.isLargeScreen(this);
  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
  double get responsiveCardWidth => ResponsiveUtils.getResponsiveCardWidth(this);
}

// Custom widgets to prevent overflow
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign textAlign;
  final TextOverflow overflow;

  const SafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.buildResponsiveText(
      text,
      style: style ?? const TextStyle(),
      context: context,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}

class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const SafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.buildFlexibleRow(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
    );
  }
}

class SafeContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;

  const SafeContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.buildSafeContainer(
      child: child,
      context: context,
      padding: padding,
      margin: margin,
      decoration: decoration,
      width: width,
      height: height,
    );
  }
}