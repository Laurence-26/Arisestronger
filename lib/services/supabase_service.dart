import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/exercise.dart';
import '../models/profile.dart';

/// Thin wrapper over Supabase for auth + all Daily Quest data access.
class SupabaseService {
  SupabaseClient get _db => Supabase.instance.client;

  // ---------------- AUTH ----------------
  User? get currentUser => _db.auth.currentUser;
  String? get uid => _db.auth.currentUser?.id;
  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _db.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  /// Google OAuth. Opens an external browser, then deep-links back into the app
  /// via [SupabaseConfig.oauthRedirect]. supabase_flutter completes the session
  /// automatically; listen to [authStateChanges] for the result.
  Future<void> signInWithGoogle() async {
    await _db.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : SupabaseConfig.oauthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _db.auth.signOut();

  // ---------------- PROFILE ----------------
  Future<Profile> fetchProfile() async {
    final id = uid!;
    final rows = await _db.from('profiles').select().eq('id', id).limit(1);
    if (rows.isEmpty) {
      // Trigger should have created it; fall back to creating it client-side.
      await _db.from('profiles').insert({'id': id, 'display_name': 'Hunter'});
      final created =
          await _db.from('profiles').select().eq('id', id).single();
      return Profile.fromMap(created);
    }
    return Profile.fromMap(rows.first);
  }

  Future<void> saveProfile(Profile p) async {
    await _db.from('profiles').update(p.toUpdateMap()).eq('id', p.id);
  }

  // ---------------- EXERCISES ----------------
  Future<List<Exercise>> fetchExercises() async {
    final rows = await _db
        .from('exercises')
        .select()
        .eq('user_id', uid!)
        .eq('active', true)
        .order('sort_order');
    return rows.map<Exercise>((m) => Exercise.fromMap(m)).toList();
  }

  Future<Exercise> addExercise(Exercise e) async {
    final inserted = await _db
        .from('exercises')
        .insert(e.toInsertMap(uid!))
        .select()
        .single();
    return Exercise.fromMap(inserted);
  }

  Future<void> deleteExercise(String id) async {
    await _db
        .from('exercises')
        .update({'active': false}).eq('id', id).eq('user_id', uid!);
  }

  // ---------------- DAILY STATE ----------------
  /// Returns the checks map { exerciseId: bool } for [day], or empty.
  Future<Map<String, bool>> fetchChecks(String day) async {
    final rows = await _db
        .from('daily_state')
        .select('checks, completed')
        .eq('user_id', uid!)
        .eq('day', day)
        .limit(1);
    if (rows.isEmpty) return {};
    final checks = (rows.first['checks'] as Map?) ?? {};
    return checks.map((k, v) => MapEntry(k.toString(), v == true));
  }

  Future<bool> isDayCompleted(String day) async {
    final rows = await _db
        .from('daily_state')
        .select('completed')
        .eq('user_id', uid!)
        .eq('day', day)
        .limit(1);
    if (rows.isEmpty) return false;
    return rows.first['completed'] == true;
  }

  Future<void> saveChecks(String day, Map<String, bool> checks,
      {bool completed = false}) async {
    await _db.from('daily_state').upsert({
      'user_id': uid!,
      'day': day,
      'checks': checks,
      'completed': completed,
    }, onConflict: 'user_id,day');
  }

  // ---------------- HISTORY ----------------
  Future<Set<String>> fetchHistory({int lastDays = 60}) async {
    final from = DateTime.now()
        .subtract(Duration(days: lastDays))
        .toIso8601String()
        .substring(0, 10);
    final rows = await _db
        .from('quest_history')
        .select('day')
        .eq('user_id', uid!)
        .gte('day', from);
    return rows.map<String>((m) => m['day'].toString()).toSet();
  }

  Future<void> addHistory(String day) async {
    await _db.from('quest_history').upsert(
      {'user_id': uid!, 'day': day},
      onConflict: 'user_id,day',
    );
  }

  // ---------------- PENALTIES ----------------
  Future<Set<String>> fetchPenalties({int lastDays = 60}) async {
    final from = DateTime.now()
        .subtract(Duration(days: lastDays))
        .toIso8601String()
        .substring(0, 10);
    final rows = await _db
        .from('penalties')
        .select('day')
        .eq('user_id', uid!)
        .gte('day', from);
    return rows.map<String>((m) => m['day'].toString()).toSet();
  }

  Future<void> addPenalty(String day, int amount) async {
    await _db.from('penalties').upsert(
      {'user_id': uid!, 'day': day, 'amount': amount},
      onConflict: 'user_id,day',
    );
  }
}
