import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 2.0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
    );
  }
}
