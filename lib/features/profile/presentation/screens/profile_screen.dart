import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/tunisia_phone.dart';
import '../../../../core/utils/validators.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          // Avatar + name header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: user?.photoUrl != null
                    ? ClipOval(
                        child:
                            Image.network(user!.photoUrl!, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyBlue),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(user?.fullName ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                  user?.clientType == ClientType.b2b
                      ? (user?.companyName ?? '')
                      : 'Particulier',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 8),
          _ProfileMenuItem(
            icon: Icons.person_outline,
            label: 'Gérer le profil',
            onTap: () => _showEditProfile(context, ref, user),
          ),
          _ProfileMenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.lock_outlined,
            label: 'Changer le mot de passe',
            onTap: () => _showChangePassword(context, ref),
          ),
          _ProfileMenuItem(
            icon: Icons.description_outlined,
            label: 'Termes et conditions',
            onTap: () => context.push('/terms'),
          ),
          _ProfileMenuItem(
            icon: Icons.help_outline,
            label: 'Assistance',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _ProfileMenuItem(
            icon: Icons.logout,
            label: 'Déconnexion',
            color: AppColors.cancelled,
            onTap: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text('INWIN v1.0.0',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog first to avoid context issues
              Navigator.of(context, rootNavigator: true).pop();

              await ref.read(authServiceProvider).signOut();
              // No manual context.go('/login') here.
              // The GoRouter redirect logic handles it automatically.
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.cancelled),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, user) {
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.fullName);
    final companyCtrl = TextEditingController(text: user.companyName);
    final phoneCtrl = TextEditingController(
      text: TunisiaPhone.localPart(user.phone),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Modifier le profil',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ))),
              if (user.clientType == ClientType.b2b) ...[
                const SizedBox(height: 12),
                TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                        labelText: "Nom d'entreprise",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ))),
              ],
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixText: '${TunisiaPhone.countryCode} ',
                      helperText: '8 chiffres',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final phoneError = Validators.phone(phoneCtrl.text);
                    if (phoneError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(phoneError)),
                      );
                      return;
                    }

                    await ref.read(authServiceProvider).updateProfile(
                          user.uid,
                          fullName: nameCtrl.text.trim(),
                          companyName: user.clientType == ClientType.b2b
                              ? companyCtrl.text.trim()
                              : null,
                          phone: TunisiaPhone.normalize(phoneCtrl.text),
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Sauvegarder'),
                ),
              ),
            ]),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Changer le mot de passe'),
        content: const Text(
            'Un lien de réinitialisation sera envoyé à votre adresse e-mail.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider).valueOrNull;
              if (user != null) {
                await ref.read(authServiceProvider).resetPassword(user.email);
              }
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Email de réinitialisation envoyé.')),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileMenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Column(children: [
      ListTile(
        tileColor: Colors.white,
        leading: Icon(icon, color: c, size: 22),
        title: Text(label,
            style:
                TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w400)),
        trailing: color == null
            ? const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textHint)
            : null,
        onTap: onTap,
      ),
      const Divider(height: 0.5, indent: 56),
    ]);
  }
}
