import 'package:evento_ticket_scanner/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings_provider.dart';
import '../services/basic_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final mode = settings.themeMode;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: isDark ? Colors.black : Colors.white,
            elevation: 0.5,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: AppColors.primaryColor,
                  inactiveThumbColor: AppColors.primaryColor,
                  inactiveTrackColor: Colors.white,
                  activeTrackColor: Colors.white,
                  value: settings.vibrateOnScan,
                  trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return null;
                    }
                    return AppColors.primaryColor;
                  }),
                  onChanged: (v) =>
                      context.read<AppSettingsProvider>().setVibrateOnScan(v),
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate on scan success'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: isDark ? Colors.black : Colors.white,
            elevation: 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Theme'),
                  subtitle: Text('Choose app appearance'),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SegmentedButton<ThemeMode>(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.settings_suggest_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) {
                        context.read<AppSettingsProvider>().setThemeMode(
                          selection.first,
                        );
                      }
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart App'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  await BasicService.ensureBrandingCached(force: true);
                } catch (_) {}
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/splash', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
