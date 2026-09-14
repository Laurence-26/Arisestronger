import 'package:flutter/material.dart';

import '../models/level.dart';
import '../services/local_database.dart';
import '../theme.dart';
import '../widgets/brand_wordmark.dart';
import '../widgets/system_button.dart';

/// Local profile picker — every Hunter lives only in this device's SQLite
/// database: no email, no password, no server.
class HunterSelectScreen extends StatefulWidget {
  final ValueChanged<String> onSelected;
  const HunterSelectScreen({super.key, required this.onSelected});

  @override
  State<HunterSelectScreen> createState() => _HunterSelectScreenState();
}

class _HunterSelectScreenState extends State<HunterSelectScreen> {
  final _name = TextEditingController();
  List<HunterSummary>? _hunters;
  bool _creating = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHunters();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadHunters() async {
    final list = await LocalDatabase.instance.listHunters();
    if (!mounted) return;
    setState(() {
      _hunters = list;
      _creating = list.isEmpty;
    });
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a Hunter name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await LocalDatabase.instance.createHunter(name);
      widget.onSelected(id);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(HunterSummary h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        title: Text('Delete ${h.name}?',
            style: const TextStyle(color: AppColors.textBright)),
        content: const Text(
          'This Hunter, their streak, and their quest history will be erased from this device.',
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await LocalDatabase.instance.deleteHunter(h.id);
    await _loadHunters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              children: [
                Text('◈ THE SYSTEM ◈',
                    textAlign: TextAlign.center,
                    style: monoStyle(
                        size: 11, color: AppColors.gold, spacing: 5)),
                const SizedBox(height: 16),
                const Center(child: BrandWordmark(size: 36)),
                const SizedBox(height: 8),
                Text('100% offline. Your Hunters never leave this device.',
                    textAlign: TextAlign.center,
                    style: monoStyle(size: 11, spacing: 0.4)),
                const SizedBox(height: 32),
                if (_hunters == null)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  )
                else if (_creating)
                  _createForm()
                else
                  _picker(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _picker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SELECT HUNTER', style: monoStyle(size: 10, spacing: 3)),
        const SizedBox(height: 10),
        for (final h in _hunters!)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.bg2,
              child: ListTile(
                onTap: () => widget.onSelected(h.id),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(h.name,
                    style: const TextStyle(
                        color: AppColors.textBright,
                        fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Streak ${h.streak} · ${h.totalDays} days · ${kLevels[levelIndexOf(h.totalDays)].rank}-Rank',
                  style: monoStyle(size: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textDim),
                  onPressed: () => _delete(h),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SystemButton(
          label: 'AWAKEN NEW HUNTER',
          ghost: true,
          onPressed: () => setState(() => _creating = true),
        ),
      ],
    );
  }

  Widget _createForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('HUNTER NAME', style: monoStyle(size: 10, spacing: 3)),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          style: const TextStyle(color: AppColors.textBright),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Sung Jin-Woo'),
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: 20),
        SystemButton(
          label: 'ARISE',
          busy: _busy,
          onPressed: _create,
        ),
        if (_hunters!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SystemButton(
            label: 'BACK',
            ghost: true,
            onPressed: () => setState(() => _creating = false),
          ),
        ],
      ],
    );
  }
}
