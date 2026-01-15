import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';

import 'home_screen.dart';
import '../scanner/qr_scanner_page.dart';
import '../profile/profile_screen.dart';
import 'providers/dashboard_provider.dart';
import '../auth/providers/auth_provider.dart';

class MainNavScreen extends StatefulWidget {
  final int initialTab;
  const MainNavScreen({super.key, this.initialTab = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;

    // Only reload when coming back from result screen (initialTab = 0 from navigation)
    if (_index == 0 && widget.initialTab == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final auth = context.read<AuthProvider>();
        if (auth.token != null && auth.profile != null) {
          context.read<DashboardProvider>().loadData(
            token: auth.token!,
            role: auth.profile!.role,
          );
        }
      });
    }
  }

  void _onTabChanged(int newIndex) {
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          QrScannerPage(isActive: _index == 1, showBack: false),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          _buildNavItem(0, 'Home', Icons.home_outlined, Icons.home),
          _buildNavItem(1, 'Scanner', Icons.qr_code_scanner, Icons.qr_code_2),
          _buildNavItem(2, 'Profile', Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon,
    IconData selectedIcon,
  ) {
    final isSelected = _index == index;
    final color = isSelected ? AppColors.primaryColor : Colors.grey.shade600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: isDark ? Colors.grey.shade900 : Colors.transparent,
        child: InkWell(
          onTap: () => _onTabChanged(index),
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(isSelected ? selectedIcon : icon, size: 28, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
