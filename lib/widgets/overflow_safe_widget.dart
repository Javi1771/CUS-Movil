import 'package:flutter/material.dart';

/// Widget que previene automáticamente los errores de overflow
class OverflowSafeWidget extends StatelessWidget {
  final Widget child;
  final Axis direction;
  final bool enableScrolling;
  final bool enableClipping;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const OverflowSafeWidget({
    super.key,
    required this.child,
    this.direction = Axis.horizontal,
    this.enableScrolling = false,
    this.enableClipping = true,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = child;

    // Aplicar padding si se especifica
    if (padding != null) {
      wrappedChild = Padding(
        padding: padding!,
        child: wrappedChild,
      );
    }

    // Aplicar margin si se especifica
    if (margin != null) {
      wrappedChild = Container(
        margin: margin,
        child: wrappedChild,
      );
    }

    // Manejar overflow según la dirección
    if (enableScrolling) {
      if (direction == Axis.horizontal) {
        wrappedChild = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: wrappedChild,
        );
      } else {
        wrappedChild = SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const ClampingScrollPhysics(),
          child: wrappedChild,
        );
      }
    } else if (enableClipping) {
      wrappedChild = ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          child: wrappedChild,
        ),
      );
    }

    return wrappedChild;
  }
}

/// Widget específico para filas que pueden tener overflow
class OverflowSafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool enableScrolling;

  const OverflowSafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.enableScrolling = false,
  });

  @override
  Widget build(BuildContext context) {
    if (enableScrolling) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        return Flexible(child: child);
      }).toList(),
    );
  }
}

/// Widget específico para columnas que pueden tener overflow
class OverflowSafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool enableScrolling;

  const OverflowSafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.enableScrolling = false,
  });

  @override
  Widget build(BuildContext context) {
    if (enableScrolling) {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        return Flexible(child: child);
      }).toList(),
    );
  }
}

/// Widget para texto que previene overflow automáticamente
class OverflowSafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  const OverflowSafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: maxLines != null && maxLines! > 1,
    );
  }
}
