import 'package:flutter/material.dart';

import '../theme.dart';

/// Shown when Supabase credentials haven't been pasted into supabase_config.dart.
class NotConfiguredScreen extends StatelessWidget {
  const NotConfiguredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('◈ SYSTEM OFFLINE ◈',
                  style: monoStyle(
                      size: 13, color: AppColors.gold, spacing: 4)),
              const SizedBox(height: 16),
              const Text('Supabase not configured',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBright)),
              const SizedBox(height: 16),
              const Text(
                'Open lib/config/supabase_config.dart and paste your '
                'Project URL and anon key, then run the SQL in '
                'supabase/schema.sql from your Supabase dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDim, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
