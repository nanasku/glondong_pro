import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth = 600,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth!),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}
