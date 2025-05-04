import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar.large(
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
      ),
      backgroundColor: colorScheme.surface,
      iconTheme: IconThemeData(
        color: colorScheme.primary,
      ),
      actions: actions,
      expandedHeight: 140,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Icon(
                icon,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(200);
}