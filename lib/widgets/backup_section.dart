import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/system_button.dart';

/// Export / import controls for the Profile tab. Everything stays on device.
class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  final _service = BackupService();
  bool _busy = false;

  Future<void> _export() async {
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final json = await _service.exportJson();
      final name = _service.suggestedFileName();
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, name));
      await file.writeAsString(json);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: name)],
        fileNameOverrides: [name],
        subject: 'AriseStronger backup',
        text: 'AriseStronger backup — keep this file to restore your progress.',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (e) {
      _tell('Export failed: $e', AppColors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final picked = await openFile(acceptedTypeGroups: const [
        XTypeGroup(
          label: 'AriseStronger backup',
          extensions: ['json'],
          mimeTypes: ['application/json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ]);
      if (picked == null) return;

      final json = await picked.readAsString();
      final preview = await _service.inspect(json);
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bg2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          title: const Text('Restore backup?',
              style: TextStyle(color: AppColors.textBright)),
          content: Text(
            'This replaces every Hunter on this device with '
            '${preview.hunters} Hunter(s), ${preview.days} completed days, '
            'and ${preview.exercises} exercises.',
            style: const TextStyle(color: AppColors.textDim, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('RESTORE'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final result = await _service.restore(json);
      await NotificationService.instance.cancelAll();
      _tell(
        'Restored ${result.hunters} Hunter${result.hunters == 1 ? '' : 's'} · '
        '${result.daysRestored} days · ${result.exercises} exercises.',
        AppColors.green,
      );
      await Session.instance.signOut();
    } on BackupFormatException catch (e) {
      _tell(e.message, AppColors.red);
    } catch (e) {
      _tell('Import failed: $e', AppColors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tell(String msg, Color _) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.bg3,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('BACKUP', style: monoStyle(size: 10, spacing: 3)),
        ),
        Text(
          'Your progress lives only on this phone. Export a JSON file to keep a copy.',
          style: monoStyle(size: 11, spacing: 0.3),
        ),
        const SizedBox(height: 12),
        SystemButton(
          label: 'EXPORT BACKUP',
          ghost: true,
          busy: _busy,
          onPressed: _export,
        ),
        const SizedBox(height: 8),
        SystemButton(
          label: 'IMPORT BACKUP',
          ghost: true,
          busy: _busy,
          onPressed: _import,
        ),
      ],
    );
  }
}
