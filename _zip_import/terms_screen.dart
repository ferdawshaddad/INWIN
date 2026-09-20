import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_theme.dart';

/// Standalone Terms & Conditions screen.
/// Accessible from Profile → Termes et Conditions.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Termes et Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _TermsContent(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── The actual T&C content (reused in the modal too) ─────────────────────
class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel_outlined,
                  size: 28, color: AppColors.navyBlue),
            ),
            const SizedBox(height: 12),
            const Text('Conditions Générales de Vente',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('INWIN — En vigueur à partir de janvier 2025',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 24),

        _Section('1. Objet', '''
Les présentes Conditions Générales de Vente (CGV) régissent l\'ensemble des relations commerciales entre INWIN (ci-après "le Prestataire") et tout client (ci-après "le Client") passant commande de cadeaux d\'entreprise personnalisés ou de services événementiels.

Toute commande implique l\'acceptation sans réserve des présentes conditions.'''),

        _Section('2. Processus de commande', '''
2.1. Le Client soumet une demande de devis via l\'application INWIN en précisant ses besoins (type de produit, matière, quantité, logo et positionnement souhaité).

2.2. INWIN examine la demande, consulte ses fournisseurs partenaires, et communique un devis au Client dans un délai de 24 à 48 heures ouvrables.

2.3. Le devis est valable 7 jours calendaires à compter de sa date d\'émission.

2.4. L\'acceptation du devis par le Client entraîne automatiquement la génération d\'un Bon de Commande officiel.'''),

        _Section('3. Bon de commande et engagement', '''
3.1. Le Bon de Commande constitue le document contractuel liant le Client à INWIN.

3.2. Le Client s\'engage à télécharger, imprimer, signer et retourner le Bon de Commande à INWIN avant tout démarrage de production.

3.3. Aucune commande ne sera lancée en production sans réception du Bon de Commande signé accompagné du versement de l\'acompte requis.

3.4. Le Bon de Commande signé vaut accord définitif sur les spécifications techniques (modèle, matière, quantité, positionnement du logo).'''),

        _Section('4. Modalités de paiement', '''
4.1. En l\'absence de solution de paiement en ligne disponible, les règlements s\'effectuent exclusivement par :
   • Virement bancaire sur le compte INWIN
   • Chèque à l\'ordre de INWIN
   • Espèces (remise en main propre)

4.2. Un acompte de 50% du montant total TTC est exigé à la confirmation de commande, avant tout démarrage de production.

4.3. Le solde de 50% est payable à la livraison ou à la mise à disposition des produits.

4.4. Tout retard de paiement entraîne de plein droit l\'application d\'une pénalité de retard de 1,5% par mois, conformément à la législation tunisienne en vigueur.'''),

        _Section('5. Délais de production et livraison', '''
5.1. Les délais de production communiqués dans le devis sont indicatifs et courent à partir de la réception du Bon de Commande signé ET de l\'acompte.

5.2. INWIN s\'engage à informer le Client de tout retard prévisible dès qu\'il en a connaissance.

5.3. La livraison s\'effectue à l\'adresse indiquée lors de la commande. Les frais de livraison sont précisés dans le devis.'''),

        _Section('6. Validation du logo et fichiers graphiques', '''
6.1. Le Client est seul responsable de la qualité et de la conformité des fichiers fournis (logo, visuels, textes).

6.2. Le positionnement du logo indiqué dans l\'application est fourni à titre indicatif. Des variations mineures peuvent survenir selon les contraintes techniques de fabrication.

6.3. Un bon à tirer (BAT) sera soumis au Client pour validation avant toute mise en production. Toute modification demandée après validation du BAT pourra entraîner des frais supplémentaires.

6.4. INWIN décline toute responsabilité pour les erreurs de contenu (fautes, erreurs graphiques) non signalées avant validation du BAT.'''),

        _Section('7. Droit de propriété intellectuelle', '''
7.1. Le Client garantit être titulaire des droits sur les logos, marques et visuels qu\'il transmet à INWIN.

7.2. Le Client autorise INWIN à utiliser ses visuels à des fins de production uniquement.

7.3. INWIN peut, sauf opposition explicite du Client, utiliser les réalisations à des fins de communication commerciale (portfolio, réseaux sociaux, application).'''),

        _Section('8. Annulation et modification', '''
8.1. Toute annulation après signature du Bon de Commande et versement de l\'acompte entraîne la perte de l\'acompte.

8.2. Toute modification de commande après lancement en production est soumise à l\'accord d\'INWIN et peut entraîner des frais supplémentaires et un allongement des délais.

8.3. En cas d\'annulation avant démarrage de la production mais après signature du Bon de Commande, des frais administratifs de 10% du montant total peuvent être retenus.'''),

        _Section('9. Réclamations et garanties', '''
9.1. Toute réclamation relative à un défaut de conformité doit être formulée par écrit dans les 48 heures suivant la livraison.

9.2. En cas de défaut avéré imputable à INWIN, le Prestataire s\'engage à reprendre ou remplacer les produits non conformes dans les meilleurs délais.

9.3. La garantie ne couvre pas les défauts résultant d\'une mauvaise utilisation, de fichiers graphiques de mauvaise qualité fournis par le Client, ou de modifications demandées après validation du BAT.'''),

        _Section('10. Droit applicable et litiges', '''
10.1. Les présentes CGV sont soumises au droit tunisien.

10.2. En cas de litige, les parties s\'engagent à rechercher une solution amiable avant tout recours judiciaire.

10.3. À défaut d\'accord amiable, les tribunaux de Tunis seront seuls compétents.'''),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.navyBlue.withOpacity(0.15)),
          ),
          child: const Text(
            'INWIN — Tunis, Tunisie\n'
            'Contact : contact@inwin.tn\n'
            'Dernière mise à jour : Janvier 2025',
            style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
              height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.navyBlue)),
          const SizedBox(height: 7),
          Text(body,
            style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary,
              height: 1.65)),
        ],
      ),
    );
  }
}

// ─── Terms acceptance modal — shown when customer accepts a quote ──────────
/// Show this before generating the bon de commande.
/// Returns true if accepted, false/null if dismissed.
Future<bool?> showTermsAcceptanceModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _TermsAcceptanceSheet(),
  );
}

class _TermsAcceptanceSheet extends StatefulWidget {
  const _TermsAcceptanceSheet();
  @override
  State<_TermsAcceptanceSheet> createState() => _TermsAcceptanceSheetState();
}

class _TermsAcceptanceSheetState extends State<_TermsAcceptanceSheet> {
  bool _accepted = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.08),
                  shape: BoxShape.circle),
                child: const Icon(Icons.gavel_outlined,
                    size: 20, color: AppColors.navyBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conditions Générales de Vente',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('Veuillez lire et accepter avant de confirmer',
                      style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key points summary (always visible)
                  _KeyPoint(Icons.payments_outlined,
                    'Acompte de 50% requis',
                    'Aucune production ne démarre sans versement de l\'acompte et Bon de Commande signé.'),
                  _KeyPoint(Icons.assignment_outlined,
                    'Bon de commande obligatoire',
                    'Vous devrez télécharger, signer et remettre le bon de commande à INWIN.'),
                  _KeyPoint(Icons.cancel_outlined,
                    'Acompte non remboursable',
                    'En cas d\'annulation après signature, l\'acompte versé est acquis à INWIN.'),
                  _KeyPoint(Icons.verified_outlined,
                    'Validation BAT obligatoire',
                    'Vous validerez un bon à tirer avant démarrage de la production.'),

                  // Read full terms toggle
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        const Text('Lire les conditions complètes',
                          style: TextStyle(
                            color: AppColors.lightGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16, color: AppColors.lightGold),
                      ]),
                    ),
                  ),
                  if (_expanded) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const _TermsContent(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Accept checkbox + button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: AppColors.divider, width: 0.5))),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _accepted = !_accepted),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: _accepted
                                ? AppColors.navyBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _accepted
                                  ? AppColors.navyBlue
                                  : AppColors.divider,
                              width: 2),
                          ),
                          child: _accepted
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'J\'ai lu et j\'accepte les Conditions Générales de Vente d\'INWIN, notamment les modalités de paiement par acompte et l\'obligation du Bon de Commande signé.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _accepted
                          ? () => Navigator.pop(context, true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor:
                            AppColors.divider,
                        disabledForegroundColor:
                            AppColors.textHint),
                      child: const Text(
                          'Accepter et télécharger le Bon de Commande'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyPoint extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _KeyPoint(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.navyBlue),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(body,
                style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary,
                  height: 1.45)),
            ],
          )),
        ],
      ),
    );
  }
}
