import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/rider_auth_provider.dart';
import 'providers/rider_orders_provider.dart';
import 'providers/rider_shift_provider.dart';
import 'models/order_model.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/create_new_password_screen.dart';
import 'screens/main/main_tab_navigation.dart';
import 'screens/main/active_order_screen.dart';
import 'screens/main/order_details_screen.dart';
import 'screens/main/chat_screen.dart';
import 'screens/main/calling_screen.dart';
import 'screens/main/notifications_screen.dart';
import 'screens/main/shift_history_screen.dart';
import 'screens/main/earning_history_screen.dart';
import 'screens/main/profile_screen.dart';
import 'screens/main/profile_edit_screen.dart';
import 'screens/main/settings_screen.dart';
import 'screens/main/support_screen.dart';

Future<void>? coreServicesInitFuture;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services concurrently in background
  coreServicesInitFuture = _initCoreServices();

  // Launch UI immediately so SplashScreen displays INSTANTLY on frame 1 without delay
  runApp(const RobotInnRiderApp());
}

Future<void> _initCoreServices() async {
  try {
    await StorageService.init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    NotificationService.init().catchError((e) {
      debugPrint('Notification init error: $e');
    });
  } catch (e) {
    debugPrint('Init core services error: $e');
  }
}

class RobotInnRiderApp extends StatelessWidget {
  const RobotInnRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RiderAuthProvider()),
        ChangeNotifierProvider(create: (_) => RiderOrdersProvider()),
        ChangeNotifierProvider(create: (_) => RiderShiftProvider()),
      ],
      child: MaterialApp(
        title: 'RobotInn Rider',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/main': (context) => const MainTabNavigation(),
          '/orders': (context) => const MainTabNavigation(initialIndex: 1),
          '/notifications': (context) => const NotificationsScreen(),
          '/shifts': (context) => const ShiftHistoryScreen(),
          '/earnings': (context) => const EarningHistoryScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/profile_edit': (context) => const ProfileEditScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/support': (context) => const SupportScreen(),
        },
        onGenerateRoute: (settings) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};

          switch (settings.name) {
            case '/create_new_password':
              return MaterialPageRoute(
                builder: (_) => CreateNewPasswordScreen(
                  email: args['email']?.toString() ?? '',
                ),
              );

            case '/active_order':
              if (args['order'] is OrderModel) {
                return MaterialPageRoute(
                  builder: (_) => ActiveOrderScreen(order: args['order'] as OrderModel),
                );
              }
              break;

            case '/order_details':
              if (args['order'] is OrderModel) {
                return MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(order: args['order'] as OrderModel),
                );
              }
              break;

            case '/chat':
              return MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: args['conversationId']?.toString() ?? '',
                  title: args['title']?.toString() ?? 'Chat',
                  participantId: args['participantId']?.toString() ?? '',
                ),
              );

            case '/calling':
              return MaterialPageRoute(
                builder: (_) => CallingScreen(
                  name: args['name']?.toString() ?? 'Customer',
                  phone: args['phone']?.toString() ?? '',
                ),
              );
          }
          return null;
        },
      ),
    );
  }
}
