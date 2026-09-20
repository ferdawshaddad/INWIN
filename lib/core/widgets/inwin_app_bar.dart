import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Reusable app bar with optional subtitle and trailing actions.
class InwinAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  final Color? backgroundColor;

  const InwinAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 72 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: subtitle != null
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
              Text(subtitle!, style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
            ])
          : Text(title),
      actions: actions,
    );
  }
}
