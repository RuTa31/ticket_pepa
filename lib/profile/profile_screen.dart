import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';
import '../services/api_client.dart';
import '../common/network_app_logo.dart';
import '../common/app_colors.dart';
import '../settings/settings_screen.dart';
import '../history/scan_history_provider.dart';
import '../home/providers/dashboard_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        automaticallyImplyLeading: false,
        // title: const NetworkAppLogo(height: 28),
        title: const Text(
          'Pepa Ticket',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(profile: profile),
          const SizedBox(height: 16),
          Card(
            elevation: 0.5,
            color: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // ListTile(
                //   leading: const Icon(Icons.history),
                //   title: const Text('History'),
                //   subtitle: const Text('View your scanning history'),
                //   onTap: () => Navigator.of(context).pushNamed('/history'),
                // ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  subtitle: const Text('App preferences'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark
                            ? Colors.grey.shade900
                            : Colors.white,
                        title: const Text('Logout?'),
                        content: const Text('You will need to login again.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.primaryColor),
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      // Clear scan history
                      await context.read<ScanHistoryProvider>().clear();
                      // Clear dashboard cache
                      if (context.mounted) {
                        context.read<DashboardProvider>().clearData();
                      }
                      // Logout
                      if (context.mounted) {
                        await context.read<AuthProvider>().logout();
                      }
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (r) => false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? 'Guest User';
    final email = profile?.email ?? '-';
    final role = profile?.role.name ?? 'guest';
    final photoUrl = profile?.photoUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _AvatarWithLoader(photoUrl: photoUrl, radius: 36),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   email,
                  //   style: TextStyle(
                  //     color: isDark ? Colors.white : Colors.black,
                  //   ),
                  // ),
                  // const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? AppColors.primaryColor : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithLoader extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  const _AvatarWithLoader({required this.photoUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final url = (photoUrl != null && photoUrl!.startsWith('http'))
        ? photoUrl!
        : '';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryColor, width: 2),
      ),
      width: size,
      height: size,
      child: ClipOval(
        child: url.isEmpty
            ? Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.person, size: 28)),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                width: size,
                height: size,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.person, size: 28)),
                ),
              ),
      ),
    );
  }
}
