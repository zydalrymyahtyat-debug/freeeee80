import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const SmartPOSApp(),
    ),
  );
}

class SmartPOSApp extends StatefulWidget {
  const SmartPOSApp({super.key});

  @override
  State<SmartPOSApp> createState() => _SmartPOSAppState();
}

class _SmartPOSAppState extends State<SmartPOSApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      // Only push AuthScreen if it's enabled and not already authenticating
      if (settings.isBiometricEnabled && !AuthScreen.isAuthenticatingGlobal) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const AuthScreen(isFromBackground: true)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'نقاط البيع الذكية',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Cairo', // Recommended for Arabic if added later
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Cairo',
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', ''), // Arabic
          ],
          locale: const Locale('ar', ''), // Set default locale to Arabic
          home: settings.isBiometricEnabled ? const AuthScreen() : const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
