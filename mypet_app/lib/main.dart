import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/colors.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/establishment_provider.dart';
import 'providers/notifications_provider.dart';
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
import 'screens/tracking_screen.dart';
import 'screens/help_screen.dart';
import 'screens/estab_help_screen.dart';
import 'screens/carrinho_screen.dart';
import 'screens/pagamento_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/estab_navigation.dart';
import 'screens/estab_edit_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..update(auth),
        ),
        ChangeNotifierProvider(create: (_) => EstablishmentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
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
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':        (_) => const SplashScreen(),
        '/login':         (_) => const LoginScreen(),
        '/register':      (_) => const RegisterScreen(),
        '/home': (ctx) {
          final idx = ModalRoute.of(ctx)?.settings.arguments as int?;
          return MainNavigation(initialIndex: idx ?? 0);
        },
        '/estab-home':    (_) => const EstabNavigation(),
        '/estab-edit':    (_) => const EstabEditScreen(),
        '/admin':         (_) => const AdminScreen(),
        '/edit-profile':  (_) => const EditProfileScreen(),
        '/history':       (_) => const HistoryScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/establishment': (_) => const EstablishmentDetailScreen(),
        '/schedule':      (_) => const ScheduleScreen(),
        '/add-pet':       (_) => const AddPetScreen(),
        '/pets':          (_) => const PetsScreen(),
        '/tracking':      (_) => const TrackingScreen(),
        '/help':          (_) => const HelpScreen(),
        '/estab-help':    (_) => const EstabHelpScreen(),
        '/cart':          (_) => const CarrinhoScreen(),
        '/payment':       (_) => const PagamentoScreen(),
      },
    );
  }
}
