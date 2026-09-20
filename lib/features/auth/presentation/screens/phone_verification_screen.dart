import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/widgets/inwin_button.dart';
import '../../../../core/widgets/inwin_text_field.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const PhoneVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  final _codeCtrl = TextEditingController();
  String? _verificationId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  Future<void> _sendCode() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (e.g. on Android)
          await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
          if (mounted) context.go('/home');
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _error = e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _loading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeCtrl.text.trim(),
      );
      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = "Code invalide ou expiré.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.white, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vérification du téléphone', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 12),
            Text('Entrez le code à 6 chiffres envoyé au ${widget.phoneNumber}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            InwinTextField(
              label: 'Code de vérification',
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              prefix: const Icon(Icons.sms_outlined),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.cancelled, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            InwinButton(label: 'Vérifier', onTap: _verifyCode, loading: _loading),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _sendCode,
                child: const Text('Renvoyer le code', style: TextStyle(color: AppColors.lightGold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
