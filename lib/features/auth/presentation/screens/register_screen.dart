import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/tunisia_phone.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/inwin_button.dart';
import '../../../../core/widgets/inwin_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  ClientType _clientType = ClientType.b2b;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).register(
            fullName: _nameCtrl.text.trim(),
            companyName:
                _clientType == ClientType.b2b ? _companyCtrl.text.trim() : null,
            clientType: _clientType,
            email: _emailCtrl.text.trim(),
            phone: TunisiaPhone.normalize(_phoneCtrl.text),
            password: _passCtrl.text,
          );
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) => (v?.isEmpty ?? true) ? 'Champ requis' : null;

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
                const SizedBox(height: 24),
                IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Text('Créer un compte',
                    style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 8),
                Text('Rejoignez INWIN pour vos projets sur mesure.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                // Client Type Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _clientType = ClientType.b2b),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _clientType == ClientType.b2b
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _clientType == ClientType.b2b
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Entreprise',
                                style: TextStyle(
                                  fontWeight: _clientType == ClientType.b2b
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _clientType == ClientType.b2b
                                      ? AppColors.darkGold
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _clientType = ClientType.b2c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _clientType == ClientType.b2c
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _clientType == ClientType.b2c
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Particulier',
                                style: TextStyle(
                                  fontWeight: _clientType == ClientType.b2c
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _clientType == ClientType.b2c
                                      ? AppColors.darkGold
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                InwinTextField(
                    label: 'Nom complet',
                    controller: _nameCtrl,
                    validator: _required,
                    prefix: const Icon(Icons.person_outline, size: 20)),
                const SizedBox(height: 16),
                if (_clientType == ClientType.b2b) ...[
                  InwinTextField(
                      label: "Nom d'entreprise",
                      controller: _companyCtrl,
                      validator: _required,
                      prefix: const Icon(Icons.business_outlined, size: 20)),
                  const SizedBox(height: 16),
                ],
                InwinTextField(
                    label: 'Adresse e-mail',
                    controller: _emailCtrl,
                    validator: _required,
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(Icons.email_outlined, size: 20)),
                const SizedBox(height: 16),
                InwinTextField(
                    label: 'Numéro de téléphone',
                    controller: _phoneCtrl,
                    validator: Validators.phone,
                    keyboardType: TextInputType.phone,
                    prefix: const Icon(Icons.phone_outlined, size: 20),
                    prefixText: '${TunisiaPhone.countryCode} ',
                    hint: '12 345 678',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ]),
                const SizedBox(height: 16),
                InwinTextField(
                  label: 'Mot de passe',
                  controller: _passCtrl,
                  obscureText: _obscure,
                  validator: (v) =>
                      (v?.length ?? 0) < 6 ? 'Minimum 6 caractères' : null,
                  prefix: const Icon(Icons.lock_outlined, size: 20),
                  suffix: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
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
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.cancelled, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 32),
                InwinButton(
                    label: 'Créer un compte',
                    onTap: _register,
                    loading: _loading),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("J'ai déjà un compte ? "),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text("Se connecter",
                          style: TextStyle(
                              color: AppColors.lightGold,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
