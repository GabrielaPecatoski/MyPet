import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/establishments/establishment_detail_page.dart';
import 'features/scheduling/scheduling_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/pets/add_pet_page.dart';
import 'features/history/history_page.dart';
import 'shell/shell_page.dart';

class MyPetApp extends StatelessWidget {
  const MyPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/shell': (_) => const ShellPage(),
        '/establishment': (_) => const EstablishmentDetailPage(),
        '/scheduling': (_) => const SchedulingPage(),
        '/notifications': (_) => const NotificationsPage(),
        '/edit-profile': (_) => const EditProfilePage(),
        '/add-pet': (_) => const AddPetPage(),
        '/history': (_) => const HistoryPage(),
      },
    );
  }
}
