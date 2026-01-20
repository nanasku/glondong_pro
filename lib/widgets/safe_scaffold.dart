import 'package:flutter/material.dart';

class SafeScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  const SafeScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
      appBar: appBar,
      body: SafeArea(minimum: EdgeInsets.all(8), child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
