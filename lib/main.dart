import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/login_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/setup_screen.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/purchase_service.dart';
import 'services/theme_service.dart';
import 'services/vault_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase en modo local / sin configurar: $e");
  }

  await LocalizationService().initLanguage();
  await ThemeService().initTheme();
  PurchaseService.initializePurchaseListener();

  final vaultService = VaultService();

  runApp(SegurCelApp(vaultService: vaultService));
}

class SegurCelApp extends StatefulWidget {
  final VaultService vaultService;

  const SegurCelApp({
    super.key,
    required this.vaultService,
  });

  @override
  State<SegurCelApp> createState() => _SegurCelAppState();
}

class _SegurCelAppState extends State<SegurCelApp> with WidgetsBindingObserver {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.vaultService.isPickingFile) return;

    // Si la aplicación se minimiza, pasa a segundo plano o se bloquea la pantalla
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      if (widget.vaultService.isUnlocked) {
        widget.vaultService.lock();

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PinScreen(vaultService: widget.vaultService),
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildRootScreen() {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Esperando inicialización de Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF10141D),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(vaultService: widget.vaultService);
        }

        // Consultar el perfil principal en la colección users/{user.uid}
        return FutureBuilder<UserProfile?>(
          key: ValueKey('user_profile_${user.uid}'),
          future: widget.vaultService.fetchUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF10141D),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                ),
              );
            }

            final profile = profileSnapshot.data;
            final isPremium = profile?.isPremium ?? false;

            // Filtro Web Freemium: En entorno Web (kIsWeb), la Bóveda requiere isPremium == true en users/{uid}
            if (kIsWeb && !isPremium) {
              return PaywallScreen(
                vaultService: widget.vaultService,
                userProfile: profile,
              );
            }

            // Si es Premium o está en app móvil Android, verificamos si ya existe su bóveda
            return FutureBuilder<bool>(
              key: ValueKey('vault_check_${user.uid}'),
              future: widget.vaultService.checkVaultExists(),
              builder: (context, vaultSnapshot) {
                if (vaultSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xFF10141D),
                    body: Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    ),
                  );
                }

                final vaultExists = vaultSnapshot.data ?? false;
                if (vaultExists) {
                  return PinScreen(vaultService: widget.vaultService);
                } else {
                  return SetupScreen(vaultService: widget.vaultService);
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeService()]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'SegurCel',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService().themeMode,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF10141D),
            primaryColor: const Color(0xFF6C63FF),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              surface: Color(0xFF1E2538),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E2538),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            useMaterial3: true,
          ),
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF0F4F8),
            primaryColor: const Color(0xFF6C63FF),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              surface: Colors.white,
              onSurface: Color(0xFF10141D),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF10141D),
              elevation: 1,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              labelStyle: const TextStyle(color: Color(0xFF4A5568)),
              hintStyle: const TextStyle(color: Colors.black38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
            ),
            useMaterial3: true,
          ),
          home: _buildRootScreen(),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _buildRootScreen(),
              settings: settings,
            );
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _buildRootScreen(),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
