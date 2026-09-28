import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/setup_screen.dart';
import 'services/auth_service.dart';
import 'services/vault_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase en modo local / sin configurar: $e");
  }

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SegurCel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10141D),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          surface: Color(0xFF1E2538),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
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

          // Si el usuario está autenticado, verificamos si ya existe su bóveda
          return FutureBuilder<bool>(
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
      ),
    );
  }
}
