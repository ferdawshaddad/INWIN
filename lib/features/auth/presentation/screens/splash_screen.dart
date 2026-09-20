import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/widgets/inwin_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Hero(
              tag: 'app_logo',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: InwinLogo(height: 120),
              ),
            ),
            const SizedBox(height: 80),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.navyBlue,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement...',
              style: TextStyle(
                color: AppColors.navyBlue.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
