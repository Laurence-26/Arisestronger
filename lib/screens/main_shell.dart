import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/overlays.dart';
import '../widgets/system_button.dart';
import 'home_tab.dart';
import 'onboarding_screen.dart';
import 'profile_tab.dart';
import 'program_tab.dart';
import 'progress_tab.dart';

/// Root shell for the active Hunter: handles loading/error, gates onboarding,
/// and hosts the four-tab bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  String _lastDay = DateTime.now().toIso8601String().substring(0, 10);

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
    if (state == AppLifecycleState.resumed) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (today != _lastDay) {
        _lastDay = today;
        context.read<AppState>().refreshForNewDay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    if (s.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    if (s.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('◈ SYSTEM ERROR ◈',
                    style:
                        monoStyle(size: 12, color: AppColors.red, spacing: 3)),
                const SizedBox(height: 12),
                Text(s.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textDim)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: SystemButton(label: 'RETRY', onPressed: () => s.load()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!s.profile.onboarded) {
      return const OnboardingScreen();
    }

    // First-miss warning: show once, then clear the transient flag.
    if (s.pendingMissWarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !s.pendingMissWarning) return;
        s.acknowledgeMissWarning();
        await showMissWarningOverlay(context);
      });
    }

    const tabs = [HomeTab(), ProgramTab(), ProgressTab(), ProfileTab()];

    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _index, children: tabs)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg2,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.purple.withValues(alpha: 0.18),
            labelTextStyle: WidgetStateProperty.all(
                monoStyle(size: 10, spacing: 1)),
          ),
          child: NavigationBar(
            height: 64,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.bolt_outlined, color: AppColors.textDim),
                  selectedIcon: Icon(Icons.bolt, color: AppColors.purple),
                  label: 'QUEST'),
              NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined,
                      color: AppColors.textDim),
                  selectedIcon:
                      Icon(Icons.fitness_center, color: AppColors.purple),
                  label: 'PROGRAM'),
              NavigationDestination(
                  icon: Icon(Icons.insights_outlined, color: AppColors.textDim),
                  selectedIcon: Icon(Icons.insights, color: AppColors.purple),
                  label: 'PROGRESS'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline, color: AppColors.textDim),
                  selectedIcon: Icon(Icons.person, color: AppColors.purple),
                  label: 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }
}
