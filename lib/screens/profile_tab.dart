import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/gate_programs.dart';
import '../services/notification_service.dart';
import '../services/session.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/backup_section.dart';
import '../widgets/system_button.dart';

/// The PROFILE tab — account, reminder time, notifications, and sign out.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final reminder = TimeOfDay(
        hour: s.profile.reminderHour, minute: s.profile.reminderMinute);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('◈ HUNTER PROFILE ◈',
                style: monoStyle(size: 11, color: AppColors.purple, spacing: 4)),
            const SizedBox(height: 14),

            // Identity card
            Container(
              decoration: panelDecoration(),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.level.color.withValues(alpha: 0.12),
                      border: Border.all(color: s.level.color, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(s.level.rank,
                        style: TextStyle(
                            fontFamily: kMono,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: s.level.color)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.profile.displayName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textBright)),
                        Text(s.level.name, style: monoStyle(size: 11, spacing: 1)),
                        Text('LOCAL PROFILE · OFFLINE',
                            style: monoStyle(size: 10, spacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle('NOTIFICATIONS'),
            _tile(
              icon: Icons.alarm,
              title: 'Daily reminder',
              subtitle: reminder.format(context),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
              onTap: () async {
                final picked =
                    await showTimePicker(context: context, initialTime: reminder);
                if (picked != null) {
                  await s.setReminderTime(picked.hour, picked.minute);
                }
              },
            ),
            _tile(
              icon: Icons.shield_moon_outlined,
              title: 'Gate day',
              subtitle:
                  '${weekdayLabel(s.profile.gateWeekday)} · optional weekly raid',
              trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
              onTap: () => _pickGateDay(context, s),
            ),
            _tile(
              icon: Icons.notifications_active_outlined,
              title: 'Enable / test notifications',
              subtitle: 'Grant permission and send a test',
              onTap: () async {
                final granted =
                    await NotificationService.instance.requestPermissions();
                await NotificationService.instance.scheduleDailyReminders(
                  hour: s.profile.reminderHour,
                  minute: s.profile.reminderMinute,
                  questCompletedToday: s.completedToday,
                  isGateDay: s.isGateDay && !s.gateClearedThisWeek,
                );
                if (granted) {
                  await NotificationService.instance.showNow(
                      '◈ SYSTEM ◈', 'Notifications are active. Arise, Hunter.');
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(granted
                        ? 'Notifications enabled.'
                        : 'Permission denied — enable it in system settings.'),
                    backgroundColor: AppColors.bg3,
                  ));
                }
              },
            ),

            const SizedBox(height: 24),
            const BackupSection(),

            const SizedBox(height: 28),
            SystemButton(
              label: 'SWITCH HUNTER',
              ghost: true,
              onPressed: () async {
                await NotificationService.instance.cancelAll();
                await Session.instance.signOut();
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('ARISESTRONGER · v1.1.5',
                  style: monoStyle(size: 10, spacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickGateDay(BuildContext context, AppState s) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.bg2,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('◈ GATE DAY ◈',
                    textAlign: TextAlign.center,
                    style: monoStyle(
                        size: 12, color: AppColors.gold, spacing: 3)),
                const SizedBox(height: 8),
                Text(
                  'Pick the weekday your optional Gate Raid appears. Skipping it never penalizes you.',
                  textAlign: TextAlign.center,
                  style: monoStyle(size: 11, spacing: 0.3),
                ),
                const SizedBox(height: 14),
                for (var day = 1; day <= 7; day++)
                  ListTile(
                    onTap: () => Navigator.pop(ctx, day),
                    title: Text(weekdayLabel(day),
                        style: TextStyle(
                          color: day == s.profile.gateWeekday
                              ? AppColors.gold
                              : AppColors.textBright,
                          fontWeight: FontWeight.w600,
                        )),
                    trailing: day == s.profile.gateWeekday
                        ? const Icon(Icons.check_circle, color: AppColors.gold)
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) await s.setGateWeekday(picked);
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(t, style: monoStyle(size: 10, spacing: 3)),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: panelDecoration(),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.purple),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textBright, fontWeight: FontWeight.w600)),
        subtitle: subtitle == null || subtitle.isEmpty
            ? null
            : Text(subtitle, style: monoStyle(size: 11)),
        trailing: trailing,
      ),
    );
  }
}
