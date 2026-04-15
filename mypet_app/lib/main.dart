import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/colors.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/establishment_detail_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/add_pet_screen.dart';
import 'screens/pets_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/estab_navigation.dart';
import 'screens/admin_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyPetApp(),
    ),
  );
}

class MyPetApp extends StatelessWidget {
  const MyPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':        (_) => const SplashScreen(),
        '/login':         (_) => const LoginScreen(),
        '/register':      (_) => const RegisterScreen(),
        '/home':          (_) => const MainNavigation(),
        '/estab-home':    (_) => const EstabNavigation(),
        '/admin':         (_) => const AdminScreen(),
        '/edit-profile':  (_) => const EditProfileScreen(),
        '/history':       (_) => const HistoryScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/establishment': (_) => const EstablishmentDetailScreen(),
        '/schedule':      (_) => const ScheduleScreen(),
        '/add-pet':       (_) => const AddPetScreen(),
        '/pets':          (_) => const PetsScreen(),
      },
    );
  }
}
