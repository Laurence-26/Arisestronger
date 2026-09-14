import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_database.dart';

/// Which local Hunter is active. Lives only on this device.
class Session extends ChangeNotifier {
  Session._();
  static final Session instance = Session._();

  static const _key = 'active_hunter_id';

  String? hunterId;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == null) {
      hunterId = null;
      return;
    }
    // Previous APKs can leave a hunter id in prefs after the SQLite file was
    // replaced. Drop stale ids so we never insert a profile without a hunter.
    if (!await LocalDatabase.instance.hunterExists(stored)) {
      hunterId = null;
      await prefs.remove(_key);
      return;
    }
    hunterId = stored;
  }

  Future<void> select(String id) async {
    hunterId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
    notifyListeners();
  }

  Future<void> signOut() async {
    hunterId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }
}
