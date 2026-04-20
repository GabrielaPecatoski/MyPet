import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';

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
            Builder(
              builder: (ctx) {
                final user = ctx.watch<AuthProvider>().user;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (user != null) {
                        Navigator.pushNamed(ctx, '/home', arguments: 4);
                      } else {
                        Navigator.pushNamed(ctx, '/login');
                      }
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryLight,
                      child: user?.photoPath != null
                          ? ClipOval(
                              child: Image.file(
                                dart_io.File(user!.photoPath!),
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.person, size: 18, color: AppColors.primary),
                    ),
                  ),
                );
              },
            ),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
