/// User progression state. Mirrors the `profiles` table.
class Profile {
  final String id;
  final String displayName;
  final int totalDays;
  final int streak;
  final DateTime? lastDate;
  final bool pendingPenalty;
  final int missedDays;
  final int reminderHour;
  final int reminderMinute;
  final bool onboarded;
  final bool graceUsed; // has the one-time "first miss" warning been spent?

  const Profile({
    required this.id,
    required this.displayName,
    required this.totalDays,
    required this.streak,
    required this.lastDate,
    required this.pendingPenalty,
    required this.missedDays,
    required this.reminderHour,
    required this.reminderMinute,
    required this.onboarded,
    required this.graceUsed,
  });

  factory Profile.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.parse(v.toString());
    bool asBool(dynamic v) => v == true || v == 1 || v == '1';
    return Profile(
      id: m['id'] as String,
      displayName: (m['display_name'] as String?) ?? 'Hunter',
      totalDays: (m['total_days'] as num?)?.toInt() ?? 0,
      streak: (m['streak'] as num?)?.toInt() ?? 0,
      lastDate: parseDate(m['last_date']),
      pendingPenalty: asBool(m['pending_penalty']),
      missedDays: (m['missed_days'] as num?)?.toInt() ?? 0,
      reminderHour: (m['reminder_hour'] as num?)?.toInt() ?? 8,
      reminderMinute: (m['reminder_minute'] as num?)?.toInt() ?? 0,
      onboarded: asBool(m['onboarded']),
      graceUsed: asBool(m['grace_used']),
    );
  }

  Map<String, dynamic> toUpdateMap() => {
        'display_name': displayName,
        'total_days': totalDays,
        'streak': streak,
        'last_date': lastDate?.toIso8601String().substring(0, 10),
        'pending_penalty': pendingPenalty,
        'missed_days': missedDays,
        'reminder_hour': reminderHour,
        'reminder_minute': reminderMinute,
        'onboarded': onboarded,
        'grace_used': graceUsed,
        'updated_at': DateTime.now().toIso8601String(),
      };

  Profile copyWith({
    String? displayName,
    int? totalDays,
    int? streak,
    DateTime? lastDate,
    bool clearLastDate = false,
    bool? pendingPenalty,
    int? missedDays,
    int? reminderHour,
    int? reminderMinute,
    bool? onboarded,
    bool? graceUsed,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      totalDays: totalDays ?? this.totalDays,
      streak: streak ?? this.streak,
      lastDate: clearLastDate ? null : (lastDate ?? this.lastDate),
      pendingPenalty: pendingPenalty ?? this.pendingPenalty,
      missedDays: missedDays ?? this.missedDays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      onboarded: onboarded ?? this.onboarded,
      graceUsed: graceUsed ?? this.graceUsed,
    );
  }
}
