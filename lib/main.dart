import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'scanner/qr_scanner_page.dart';
import 'history/scan_history_provider.dart';
import 'history/scan_history_screen.dart';
import 'auth/providers/auth_provider.dart';
import 'auth/ui/screens/login_screen.dart';
import 'scanner/qr_permission_intro.dart';
import 'home/main_nav_screen.dart';
import 'home/providers/dashboard_provider.dart';
import 'scanner/qr_result_screen.dart';
import 'settings/app_settings_provider.dart';
import 'common/app_colors.dart';
import 'common/iphone_17_pro_max_frame.dart';
import 'services/basic_service.dart';
import 'auth/ui/screens/splash_screen.dart';
import 'scanner/scanner_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await BasicService.ensureBrandingCached();
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanHistoryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) => ValueListenableBuilder<int>(
          valueListenable: AppColors.themeVersion,
          builder: (context, _, __) {
            final app = MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Pepa Ticket',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primaryColor,
                ),
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.grey.shade50,
                appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primaryColor,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              themeMode: settings.themeMode,
              routes: {
                '/splash': (context) => const SplashScreen(),
                '/': (context) => const _RootGate(),
                '/login': (context) => const LoginScreen(),
                '/main': (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments as Map?;
                  final initialTab = args?['initialTab'] as int? ?? 0;
                  return MainNavScreen(initialTab: initialTab);
                },
                '/intro': (context) => const QrPermissionIntro(),
                '/scanner': (context) => const QrScannerPage(),
                '/history': (context) => const ScanHistoryScreen(),
                '/result': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  String value = '';
                  String? apiMessage;
                  String? alertType;
                  String? bookingId;
                  if (args is String) {
                    value = args;
                  } else if (args is Map) {
                    final map = args.cast<dynamic, dynamic>();
                    value =
                        map['value']?.toString() ??
                        map['code']?.toString() ??
                        '';
                    apiMessage = (map['apiMessage'] ?? map['message'])
                        ?.toString();
                    alertType = (map['alertType'] ?? map['alert_type'])
                        ?.toString();
                    bookingId = (map['booking_id'] ?? map['bookingId'])
                        ?.toString();
                  }
                  return QrResultScreen(
                    value: value,
                    apiMessage: apiMessage,
                    alertType: alertType,
                    bookingId: bookingId,
                  );
                },
              },
              initialRoute: '/splash',
            );

            // Wrap with iPhone frame on web only
            if (kIsWeb) {
              return IPhone17ProMaxFrame(child: app);
            }
            return app;
          },
        ),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }
        return const MainNavScreen();
      },
    );
  }
}
