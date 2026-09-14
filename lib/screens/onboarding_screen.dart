import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/level.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/brand_wordmark.dart';
import '../widgets/system_button.dart';

/// First-run flow: pick a Hunter name, a fitness level (sets starting rank),
/// and enable notifications. Shown until profile.onboarded becomes true.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _name;
  StartLevel _level = StartLevel.beginner;
  int _rankIndex = 0;
  TimeOfDay _reminder = const TimeOfDay(hour: 8, minute: 0);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _name = TextEditingController(
        text: p.displayName == 'Hunter' ? '' : p.displayName);
    _reminder = TimeOfDay(hour: p.reminderHour, minute: p.reminderMinute);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    setState(() => _busy = true);
    final s = context.read<AppState>();
    await NotificationService.instance.requestPermissions();
    await s.completeOnboarding(
      startRankIndex: _rankIndex,
      displayName: _name.text,
      reminderHour: _reminder.hour,
      reminderMinute: _reminder.minute,
    );
    // MainShell rebuilds into the tabs automatically once onboarded is true.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              children: [
                Text('◈ AWAKENING ◈',
                    textAlign: TextAlign.center,
                    style:
                        monoStyle(size: 11, color: AppColors.purple, spacing: 5)),
                const SizedBox(height: 16),
                const Center(child: BrandWordmark(size: 34)),
                const SizedBox(height: 10),
                Text('The System is calibrating your quest.',
                    textAlign: TextAlign.center,
                    style: monoStyle(size: 12, spacing: 1)),
                const SizedBox(height: 28),

                _label('YOUR HUNTER NAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  style: const TextStyle(color: AppColors.textBright),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Jinwoo',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.textDim),
                  ),
                ),
                const SizedBox(height: 24),

                _label('YOUR TRAINING LEVEL'),
                const SizedBox(height: 4),
                Text('A suggestion only — you still choose the starting rank.',
                    style: monoStyle(size: 11, spacing: 0.5)),
                const SizedBox(height: 10),
                ...StartLevel.values.map(_levelCard),
                const SizedBox(height: 18),

                _label('STARTING RANK'),
                const SizedBox(height: 4),
                Text(
                  'Beginner can start at D, E, or any other rank. The System will scale the quest to match.',
                  style: monoStyle(size: 11, spacing: 0.5),
                ),
                const SizedBox(height: 10),
                _rankGrid(),
                const SizedBox(height: 18),

                _label('DAILY REMINDER'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _reminder);
                    if (picked != null) setState(() => _reminder = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: panelDecoration(),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm, color: AppColors.purple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Remind me at ${_reminder.format(context)}',
                            style: const TextStyle(color: AppColors.textBright),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textDim),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SystemButton(
                  label: '◈ ARISE ◈',
                  busy: _busy,
                  onPressed: _begin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: monoStyle(size: 10, spacing: 3));

  Widget _levelCard(StartLevel level) {
    final selected = _level == level;
    final accent = kLevels[level.startLevelIndex].color;
    return GestureDetector(
      onTap: () => setState(() {
        _level = level;
        _rankIndex = level.startLevelIndex;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : AppColors.bg2,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                border: Border.all(color: accent, width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(level.rankLabel,
                  style: TextStyle(
                      fontFamily: kMono,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: accent)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level.title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.textBright
                              : AppColors.text)),
                  const SizedBox(height: 2),
                  Text(level.subtitle,
                      style: monoStyle(size: 10, spacing: 0.3)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _rankGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < kLevels.length; i++) _rankChip(i),
      ],
    );
  }

  Widget _rankChip(int i) {
    final lv = kLevels[i];
    final selected = _rankIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _rankIndex = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? lv.color.withValues(alpha: 0.16) : AppColors.bg2,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: selected ? lv.color : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: lv.color.withValues(alpha: 0.28), blurRadius: 12)]
              : null,
        ),
        child: Column(
          children: [
            Text(
              lv.rank,
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: lv.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${lv.reps} reps',
              style: monoStyle(size: 9, spacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
