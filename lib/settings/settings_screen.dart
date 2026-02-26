import 'package:evento_ticket_scanner/common/app_colors.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Text(l10n.settings),
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
                  title: Text(l10n.vibration),
                  subtitle: Text(l10n.vibrateOnScanSuccess),
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
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(l10n.theme),
                  subtitle: Text(l10n.chooseAppAppearance),
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
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.systemTheme),
                        icon: const Icon(Icons.settings_suggest_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.lightTheme),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.darkTheme),
                        icon: const Icon(Icons.dark_mode_outlined),
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
              label: Text(l10n.restartApp),
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
