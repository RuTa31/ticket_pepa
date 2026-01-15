import 'package:flutter/material.dart';
import '../common/network_app_logo.dart';
import '../common/app_colors.dart';

class QrPermissionIntro extends StatelessWidget {
  final VoidCallback? onGetStarted;
  const QrPermissionIntro({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        automaticallyImplyLeading: false,
        title: const NetworkAppLogo(height: 28),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(Icons.qr_code_2, size: 140, color: AppColors.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Please give access to your Camera so that we can scan and provide what is inside the code',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (onGetStarted != null) {
                      onGetStarted!();
                    } else {
                      Navigator.of(context).pushReplacementNamed('/scanner');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    "Let's Get Started",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
