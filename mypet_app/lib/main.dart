import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/colors.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/driver_profile_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/establishment_provider.dart';
import 'providers/establishment_staff_provider.dart';
import 'providers/history_provider.dart';
import 'providers/home_provider.dart';
import 'providers/store_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/vet_profile_provider.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/establishment_list_repository.dart';
import 'repositories/history_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/orders_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/pet_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
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
import 'screens/establishment_help_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/appointment_payment_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/establishment_navigation.dart';
import 'screens/establishment_edit_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/driver_register_screen.dart';
import 'screens/establishment_drivers_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_navigation.dart';
import 'screens/emergency_screen.dart';
import 'screens/establishment_hours_screen.dart';
import 'screens/establishment_vets_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/vet_navigation.dart';

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
        ChangeNotifierProvider(create: (_) => PagamentoProvider(PaymentRepository())),
        ChangeNotifierProvider(create: (_) => HomeProvider(EstablishmentListRepository())),
        ChangeNotifierProvider(create: (_) => PetProvider(PetRepository())),
        ChangeNotifierProvider(create: (_) => HistoryProvider(HistoryRepository())),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(NotificationRepository())),
        ChangeNotifierProvider(create: (_) => LojaProvider(CatalogRepository(), OrdersRepository())),
        ChangeNotifierProvider(create: (_) => DriverProfileProvider()),
        ChangeNotifierProvider(create: (_) => VetProfileProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => EstablishmentStaffProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
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
        '/welcome':       (_) => const WelcomeScreen(),
        '/login':         (_) => const LoginScreen(),
        '/register': (ctx) {
          final arg = ModalRoute.of(ctx)?.settings.arguments;
          final tipo = (arg is int && arg >= 0) ? arg : 0;
          return RegisterScreen(initialTipo: tipo);
        },
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
        '/cart':                    (_) => const CarrinhoScreen(),
        '/payment':                 (_) => const PagamentoScreen(),
        '/pagamento-agendamento':   (_) => const PagamentoAgendamentoScreen(),
        '/onboarding':              (_) => const OnboardingScreen(),
        '/motorista-cadastro':      (_) => const MotoristaRegisterScreen(),
        '/motoristas':              (_) => const EstabMotoristasScreen(),
        '/veterinarios':            (_) => const EstabVeterinariosScreen(),
        '/driver-home':             (_) => const DriverHomeScreen(),
        '/driver-nav':              (_) => const DriverNavigation(),
        '/vet-home':                (_) => const VetNavigation(),
        '/emergencia':              (_) => const EmergenciaScreen(),
        '/estab-horarios':          (_) => const EstabHorariosScreen(),
        '/product-detail':          (_) => const ProductDetailScreen(),
      },
    );
  }
}
