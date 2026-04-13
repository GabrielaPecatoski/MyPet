import 'package:flutter/material.dart';
import '../core/colors.dart';

class MypetAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const MypetAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.chevron_left, size: 28, color: AppColors.dark),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      title: Image.asset(
        'assets/images/logo.png',
        height: 48,
        fit: BoxFit.contain,
      ),
      actions: actions ??
          [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.person, size: 18, color: AppColors.primary),
              ),
            ),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
