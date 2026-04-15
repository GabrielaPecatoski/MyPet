import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
class MyPetAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack; final bool showProfile; final VoidCallback? onProfileTap;
  const MyPetAppBar({super.key, this.showBack=true, this.showProfile=true, this.onProfileTap});
  @override Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false,
      leading: showBack ? IconButton(icon: const Icon(Icons.arrow_back_ios, size:20), onPressed: () => Navigator.of(context).pop()) : null,
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width:30, height:30, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle), child: const Icon(Icons.pets, color: AppColors.primary, size:17)),
        const SizedBox(width:6),
        const Text('My Pet', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize:18)),
      ]),
      actions: [if (showProfile) Padding(padding: const EdgeInsets.only(right:12), child: GestureDetector(onTap: onProfileTap, child: const CircleAvatar(radius:16, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person_outline, color: AppColors.primary, size:18))))],
    );
  }
}