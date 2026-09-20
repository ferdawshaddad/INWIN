import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/models/message.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';
import '../../../../core/services/message_service.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/attachment_preview.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snack_utils.dart';
import '../../../terms/presentation/screens/terms_screen.dart';
import '../../../bon_commande/bon_commande_service.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ProjectDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _State();
}

class _State extends ConsumerState<ProjectDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sendingMsg = false;
  bool _generatingPdf = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> _sendMessage(QuoteRequest req, AppUser user) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingMsg = true);
    _msgCtrl.clear();
    try {
      await ref.read(messageServiceProvider).sendMessage(
        requestId: req.id,
        senderId: user.uid,
        senderName: user.fullName,
        isAdmin: false,
        text: text,
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sendingMsg = false);
    }
  }

  // ── Quote response ────────────────────────────────────────────────────────
  Future<void> _respondToQuote(QuoteRequest req, bool accept) async {
    if (!accept) {
      // Reject
      final confirmed = await showConfirmDialog(
        context,
        title: 'Refuser le devis ?',
        message: 'La demande sera marquée comme refusée.\n'
            'Vous pouvez envoyer un message pour négocier.',
        confirmLabel: 'Refuser',
        destructive: true,
      );
      if (confirmed == true) {
        await ref.read(requestServiceProvider)
            .respondToQuote(requestId: req.id, accepted: false);
        if (mounted) SnackUtils.info(context, 'Devis refusé.');
      }
      return;
    }

    // ── ACCEPT FLOW ──────────────────────────────────────────────────────

    // Step 1: T&C modal
    final termsAccepted = await showTermsAcceptanceModal(context);
    if (termsAccepted != true || !mounted) return;

    // Step 2: Mark accepted in Firestore
    await ref.read(requestServiceProvider)
        .respondToQuote(requestId: req.id, accepted: true);

    if (!mounted) return;

    // Step 3: Generate bon de commande PDF
    setState(() => _generatingPdf = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull!;
      final pdfBytes = await BonCommandeService.generate(
        request: req,
        customer: user,
      );
      if (mounted) {
        // Show bottom sheet to download/share
        _showBonCommandeSheet(pdfBytes, req);
      }
    } catch (e) {
      if (mounted) SnackUtils.error(context, 'Erreur PDF : $e');
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  // ── Bon de commande download sheet ────────────────────────────────────────
  void _showBonCommandeSheet(List<int> pdfBytes, QuoteRequest req) {
    final ref2 = 'BC-${DateFormat('yyyyMMdd').format(DateTime.now())}'
        '-${req.id.substring(0, 6).toUpperCase()}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            // Icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.accepted.withOpacity(0.1),
                shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  size: 36, color: AppColors.accepted),
            ),
            const SizedBox(height: 14),
            const Text('Commande confirmée !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Référence : $ref2',
              style: const TextStyle(
                color: AppColors.lightGold,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            // Instructions box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.lightGold.withOpacity(0.4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Prochaines étapes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF8B6400))),
                  SizedBox(height: 8),
                  _Step('1', 'Téléchargez et imprimez le Bon de Commande'),
                  _Step('2', 'Signez-le avec la mention "Lu et approuvé — Bon pour accord"'),
                  _Step('3', 'Remettez-le à INWIN accompagné de l\'acompte de 50%'),
                  _Step('4', 'La production démarrera à réception'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Download button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await BonCommandeService.printOrShare(
                      Uint8List.fromList(pdfBytes));
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Télécharger le Bon de Commande (PDF)'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Re-download bon de commande (for already accepted orders) ─────────────
  Future<void> _redownloadBonCommande(QuoteRequest req) async {
    setState(() => _generatingPdf = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull!;
      final pdfBytes = await BonCommandeService.generate(
          request: req, customer: user);
      await BonCommandeService.printOrShare(pdfBytes);
    } catch (e) {
      if (mounted) SnackUtils.error(context, 'Erreur PDF : $e');
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final requestAsync = ref.watch(StreamProvider(
        (ref) => ref.read(requestServiceProvider).watchRequest(widget.requestId)));
    final messagesAsync = ref.watch(StreamProvider(
        (ref) => ref.read(messageServiceProvider).watchMessages(widget.requestId)));

    return requestAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (request) {
        if (request == null) {
          return const Scaffold(
              body: Center(child: Text('Projet introuvable')));
        }
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(request.details['category'] ??
                request.details['eventType'] ?? 'Projet'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StatusBadge(status: request.status),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  const OfflineBanner(),
                  Expanded(
                    child: ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Details card
                        _SectionCard(
                          title: 'Détails de la demande',
                          child: Column(children: [
                            ...request.details.entries
                                .where((e) =>
                                    !['note', 'colors', 'logoPosition']
                                        .contains(e.key) &&
                                    e.value.toString().isNotEmpty)
                                .map((e) => _Row(
                                      label: _labelFor(e.key),
                                      value: e.key == 'eventDate'
                                          ? AppDateUtils.long(
                                              DateTime.parse(e.value))
                                          : e.value.toString(),
                                    )),
                            if (request.details['note']?.isNotEmpty == true)
                              _Row(label: 'Note',
                                  value: request.details['note']),
                            if (request.details['logoPosition'] != null)
                              _Row(label: 'Position logo',
                                  value: 'Définie via l\'app'),
                            _Row(label: 'Soumis le',
                                value: AppDateUtils.dateTime(request.createdAt)),
                          ]),
                        ),

                        // Attachments
                        if (request.attachmentUrls.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _SectionCard(
                            title: 'Fichiers joints',
                            child: AttachmentRow(
                                urls: request.attachmentUrls),
                          ),
                        ],

                        // Quote card
                        if (request.quotedPrice != null) ...[
                          const SizedBox(height: 10),
                          _QuoteCard(
                            request: request,
                            onAccept: () =>
                                _respondToQuote(request, true),
                            onReject: () =>
                                _respondToQuote(request, false),
                            onRedownload: () =>
                                _redownloadBonCommande(request),
                            generatingPdf: _generatingPdf,
                          ),
                        ],

                        // Status stepper
                        const SizedBox(height: 10),
                        _StatusStepper(status: request.status),

                        // Messages
                        const SizedBox(height: 16),
                        Row(children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 16, color: AppColors.navyBlue),
                          const SizedBox(width: 6),
                          Text('Messages',
                              style: Theme.of(context).textTheme.titleMedium),
                        ]),
                        const SizedBox(height: 10),
                        messagesAsync.when(
                          loading: () => const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator())),
                          error: (_, __) => const SizedBox(),
                          data: (msgs) {
                            if (msgs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.divider, width: 0.5),
                                ),
                                child: const Center(
                                    child: Text(
                                        'Aucun message — posez vos questions ici.',
                                        style: TextStyle(
                                            color: AppColors.textHint,
                                            fontSize: 13))),
                              );
                            }
                            _scrollToBottom();
                            return Column(
                              children: msgs
                                  .map((m) => _MessageBubble(
                                        message: m,
                                        isMe: m.senderId == user?.uid,
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  // Message input
                  _MessageInputBar(
                    controller: _msgCtrl,
                    loading: _sendingMsg,
                    onSend: user == null
                        ? null
                        : () => _sendMessage(request, user),
                  ),
                ],
              ),
              // PDF generation overlay
              if (_generatingPdf)
                Container(
                  color: Colors.black38,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(
                              color: AppColors.navyBlue),
                          SizedBox(height: 14),
                          Text('Génération du bon de commande...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _labelFor(String key) {
    const map = {
      'category': 'Catégorie', 'model': 'Modèle',
      'material': 'Matière', 'quantity': 'Quantité',
      'eventType': 'Type', 'eventDate': 'Date',
      'location': 'Lieu', 'participants': 'Participants',
      'ambiance': 'Ambiance',
    };
    return map[key] ?? key;
  }
}

// ─── Quote card ───────────────────────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final QuoteRequest request;
  final VoidCallback onAccept, onReject, onRedownload;
  final bool generatingPdf;

  const _QuoteCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onRedownload,
    required this.generatingPdf,
  });

  @override
  Widget build(BuildContext context) {
    final canRespond = request.status == RequestStatus.quoted;
    final isAccepted = request.status == RequestStatus.accepted ||
        request.status == RequestStatus.inProduction ||
        request.status == RequestStatus.delivered;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.quoted.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.quoted.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(children: [
            const Icon(Icons.local_offer_outlined,
                size: 16, color: AppColors.quoted),
            const SizedBox(width: 8),
            Text('Devis reçu',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
            const Spacer(),
            if (!canRespond) StatusBadge(status: request.status, small: true),
          ]),
          const SizedBox(height: 14),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Montant TTC',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
              Text(
                '${request.quotedPrice!.toStringAsFixed(3)} TND',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyBlue)),
            ],
          ),

          // Acompte info
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.lightGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.lightGold),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Acompte requis : '
                '${(request.quotedPrice! / 2).toStringAsFixed(3)} TND (50%)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightGold,
                  fontWeight: FontWeight.w500))),
            ]),
          ),

          if (request.adminNote?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.message_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(child: Text(request.adminNote!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.4))),
                ],
              ),
            ),
          ],

          // ── Action buttons ─────────────────────────────────────────────
          if (canRespond) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppColors.cancelled),
                    foregroundColor: AppColors.cancelled),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: generatingPdf ? null : onAccept,
                  icon: generatingPdf
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: AppColors.accepted),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            // T&C hint
            const Center(
              child: Text(
                'En acceptant vous accédez aux CGV et au Bon de Commande',
                style: TextStyle(
                  fontSize: 10, color: AppColors.textHint),
                textAlign: TextAlign.center),
            ),
          ],

          // ── Re-download bon de commande ─────────────────────────────────
          if (isAccepted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: generatingPdf ? null : onRedownload,
                icon: generatingPdf
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined, size: 16),
                label: const Text('Re-télécharger le Bon de Commande'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Step widget for download sheet ──────────────────────────────────────────
class _Step extends StatelessWidget {
  final String number, text;
  const _Step(this.number, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18, height: 18,
          decoration: const BoxDecoration(
              color: Color(0xFF8B6400), shape: BoxShape.circle),
          child: Center(child: Text(number,
            style: const TextStyle(
              color: Colors.white, fontSize: 10,
              fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5C4000),
            height: 1.4))),
      ],
    ),
  );
}

// ─── Status stepper ───────────────────────────────────────────────────────────
class _StatusStepper extends StatelessWidget {
  final RequestStatus status;
  const _StatusStepper({required this.status});

  static const _steps = [
    (RequestStatus.pending,      'En attente',   Icons.hourglass_empty),
    (RequestStatus.reviewing,    'En revue',     Icons.search),
    (RequestStatus.quoted,       'Devis reçu',   Icons.local_offer_outlined),
    (RequestStatus.accepted,     'Accepté',      Icons.thumb_up_outlined),
    (RequestStatus.inProduction, 'En production',Icons.precision_manufacturing_outlined),
    (RequestStatus.delivered,    'Livré',        Icons.local_shipping_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = _steps.indexWhere((s) => s.$1 == status);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.timeline, size: 16, color: AppColors.navyBlue),
              const SizedBox(width: 6),
              Text('Suivi de commande',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 14),
            ...List.generate(_steps.length, (i) {
              final (_, label, icon) = _steps[i];
              final done = idx >= i;
              final active = idx == i;
              final isLast = i == _steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.navyBlue
                            : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done
                              ? AppColors.navyBlue
                              : AppColors.divider,
                          width: active ? 2 : 1.5),
                      ),
                      child: done
                          ? Icon(icon,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2, height: 20,
                        color: done && idx > i
                            ? AppColors.navyBlue.withOpacity(0.3)
                            : AppColors.divider),
                  ]),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: done
                            ? AppColors.textPrimary
                            : AppColors.textHint)),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Reused sub-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: AppColors.lightGold, shape: BoxShape.circle),
                  child: const Center(child: Text('I',
                    style: TextStyle(
                      color: Colors.white, fontSize: 9,
                      fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 5),
                const Text('INWIN',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.lightGold, letterSpacing: 0.5)),
              ]),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.navyBlue : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16)),
              border: isMe
                  ? null
                  : Border.all(
                      color: AppColors.divider, width: 0.5),
            ),
            child: Text(message.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14, height: 1.45)),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(AppDateUtils.time(message.createdAt),
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint)),
          ),
        ],
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback? onSend;

  const _MessageInputBar({
    required this.controller,
    required this.loading,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend?.call(),
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.navyBlue, width: 1.5)),
                fillColor: AppColors.surface,
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: onSend != null
                    ? AppColors.navyBlue
                    : AppColors.divider,
                shape: BoxShape.circle),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                  : const Icon(Icons.send,
                      color: Colors.white, size: 17),
            ),
          ),
        ]),
      ),
    );
  }
}
