import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'services/local_database.dart';
import 'services/notification_service.dart';
import 'services/quest_service.dart';
import 'services/session.dart';
import 'state/app_state.dart';
import 'screens/hunter_select_screen.dart';
import 'screens/main_shell.dart';
import 'theme.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await LocalDatabase.instance.open();
  await Session.instance.restore();
  await NotificationService.instance.init();

  runApp(const DailyQuestApp());
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
      home: const HunterGate(),
    );
  }
}

/// Swaps between the local Hunter picker and the app, following [Session].
class HunterGate extends StatelessWidget {
  const HunterGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final id = Session.instance.hunterId;
        if (id == null) {
          return HunterSelectScreen(onSelected: Session.instance.select);
        }
        return ChangeNotifierProvider(
          key: ValueKey(id),
          create: (_) => AppState(QuestService(id))..load(),
          child: const MainShell(),
        );
      },
    );
  }
}
