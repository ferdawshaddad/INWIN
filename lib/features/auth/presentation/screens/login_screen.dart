import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/inwin_button.dart';
import '../../../../core/widgets/inwin_logo.dart';
import '../../../../core/widgets/inwin_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ref.read(authServiceProvider).signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (user != null && mounted) {
        context.go(user.role == UserRole.admin ? '/admin' : '/home');
      } else if (mounted) {
        setState(() => _error = "Compte non trouvé.");
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(child: InwinLogo()),
                const SizedBox(height: 48),
                Text('Se connecter', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 8),
                Text('Bienvenue ! Entrez vos identifiants.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                InwinTextField(
                  label: 'Adresse e-mail',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                InwinTextField(
                  label: 'Mot de passe',
                  controller: _passCtrl,
                  obscureText: _obscure,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Champ requis' : null,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cancelled.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.cancelled, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(context),
                    child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.lightGold)),
                  ),
                ),
                const SizedBox(height: 24),
                InwinButton(label: 'Se connecter', onTap: _login, loading: _loading),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("Pas encore de compte ? "),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text("S'inscrire", style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Réinitialiser le mot de passe'),
        content: InwinTextField(
          label: 'Adresse e-mail',
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () async {
              await ref.read(authServiceProvider).resetPassword(ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
