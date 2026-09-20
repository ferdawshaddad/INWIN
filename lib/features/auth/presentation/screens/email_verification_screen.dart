import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/inwin_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    // Check verification status every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await ref.read(authServiceProvider).reloadUser();
      if (!context.mounted) return;
      if (ref.read(authServiceProvider).isEmailVerified()) {
        timer.cancel();
        _goHome();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      
      if (!mounted) return;
      
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Un nouvel e-mail de confirmation a été envoyé.'),
          backgroundColor: AppColors.accepted,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _canResend = false;
        _resendTimer = 60;
      });
      _startResendTimer();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.cancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  void _goHome() {
    if (!mounted) return;
    context.go('/home');
  }

  void _startResendTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: AppColors.lightGold),
              const SizedBox(height: 24),
              Text(
                'Vérifiez votre e-mail',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nous avons envoyé un lien de confirmation à votre adresse e-mail. Veuillez cliquer sur le lien pour activer votre compte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 16),
              const Text(
                'Attente de confirmation...',
                style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textHint),
              ),
              const SizedBox(height: 48),
              InwinButton(
                label: _canResend ? 'Renvoyer l\'e-mail' : 'Renvoyer dans ${_resendTimer}s',
                onTap: _canResend ? _resendEmail : null,
                color: _canResend ? AppColors.navyBlue : AppColors.divider,
              ),
              TextButton(
                onPressed: _signOut,
                child: const Text('Retour à la connexion', style: TextStyle(color: AppColors.textHint)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
