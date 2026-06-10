import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'state/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/not_configured_screen.dart';
import 'theme.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Hold the native splash through async startup (no white flash).
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.key,
    );
    await NotificationService.instance.init();
  }

  runApp(const DailyQuestApp());
  // Remove the splash once the first frame is painted.
  binding.addPostFrameCallback((_) => FlutterNativeSplash.remove());
}

class DailyQuestApp extends StatelessWidget {
  const DailyQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AriseStronger',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: SupabaseConfig.isConfigured
          ? const AuthGate()
          : const NotConfiguredScreen(),
    );
  }
}

/// Listens to Supabase auth and swaps between the login screen and the app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _svc = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _svc.authStateChanges,
      builder: (context, snapshot) {
        final session = _svc.currentUser;
        if (session == null) {
          return AuthScreen(service: _svc);
        }
        // Logged in — build app state scoped to this session.
        return ChangeNotifierProvider(
          key: ValueKey(session.id),
          create: (_) => AppState(_svc)..load(),
          child: const MainShell(),
        );
      },
    );
  }
}
