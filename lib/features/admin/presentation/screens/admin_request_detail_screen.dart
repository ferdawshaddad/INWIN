import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/models/message.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';
import '../../../../core/services/message_service.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/attachment_preview.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snack_utils.dart';

class AdminRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const AdminRequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<AdminRequestDetailScreen> createState() => _State();
}

class _State extends ConsumerState<AdminRequestDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sendingMsg = false;
  static const double _tvaRate = 0.19;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Quote dialog ────────────────────────────────────────────────────────
  Future<void> _showSendQuoteDialog(QuoteRequest request) async {
    final supplierCtrl =
        TextEditingController(text: request.supplierPrice?.toStringAsFixed(0));
    final quotedHtCtrl = TextEditingController(
        text: request.quotedPrice == null
            ? null
            : _ttcToHt(request.quotedPrice!).toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: request.adminNote ?? '');

    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Envoyer un devis',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          '${request.customerName}  ·  ${request.companyName ?? 'Particulier'}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                // Supplier price (internal — never visible to customer)
                TextField(
                  controller: supplierCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Prix fournisseur (interne)',
                    prefixText: 'TND  ',
                    helper: const Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 12, color: AppColors.textHint),
                        SizedBox(width: 4),
                        Text('Jamais visible par le client',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                // Margin preview
                _MarginPreview(
                    supplierCtrl: supplierCtrl, quotedHtCtrl: quotedHtCtrl),
                const SizedBox(height: 12),
                // Quoted price entered HT, stored and shown to customers as TTC.
                TextField(
                  controller: quotedHtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Prix client HT',
                    prefixText: 'TND  ',
                    helper: const Row(
                      children: [
                        Icon(Icons.visibility_rounded,
                            size: 12, color: AppColors.lightGold),
                        SizedBox(width: 4),
                        Text('TTC calculé automatiquement avec TVA 19%',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.lightGold)),
                      ],
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message au client (optionnel)',
                    hintText: 'Ex: délai de livraison, conditions spéciales...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final sp = _parseAmount(supplierCtrl.text);
                            final ht = _parseAmount(quotedHtCtrl.text);
                            if (sp == null || ht == null) {
                              SnackUtils.error(context,
                                  'Veuillez entrer des montants valides.');
                              return;
                            }
                            final qp = _htToTtc(ht);
                            setModal(() => loading = true);
                            try {
                              await ref.read(requestServiceProvider).sendQuote(
                                    requestId: request.id,
                                    supplierPrice: sp,
                                    quotedPrice: qp,
                                    adminNote: noteCtrl.text.trim().isEmpty
                                        ? null
                                        : noteCtrl.text.trim(),
                                  );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                SnackUtils.success(ctx,
                                    'Devis TTC de ${qp.toStringAsFixed(0)} TND envoyé au client.');
                              }
                            } catch (e) {
                              setModal(() => loading = false);
                              if (ctx.mounted) {
                                SnackUtils.error(ctx, 'Erreur: $e');
                              }
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Envoyer le devis au client'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Status update shortcuts ─────────────────────────────────────────────
  Future<void> _updateStatus(
      QuoteRequest req, RequestStatus next, String label) async {
    final confirmed = await showConfirmDialog(
      context,
      title: label,
      message: 'Confirmer le changement de statut vers « ${next.label} » ?',
    );
    if (confirmed == true) {
      await ref.read(requestServiceProvider).updateStatus(req.id, next);
      if (mounted) SnackUtils.success(context, 'Statut mis à jour.');
    }
  }

  // ── Send admin message ──────────────────────────────────────────────────
  Future<void> _sendMessage(QuoteRequest req, AppUser user) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingMsg = true);
    _msgCtrl.clear();
    try {
      await ref.read(messageServiceProvider).sendMessage(
            requestId: req.id,
            senderId: user.uid,
            senderName: 'INWIN',
            isAdmin: true,
            text: text,
          );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sendingMsg = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final requestAsync = ref.watch(quoteRequestProvider(widget.requestId));
    final messagesAsync = ref.watch(requestMessagesProvider(widget.requestId));

    return requestAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (request) {
        if (request == null) {
          return const Scaffold(body: Center(child: Text('Introuvable')));
        }
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(request.customerName,
                    style: const TextStyle(fontSize: 16)),
                Text(request.companyName ?? 'Particulier',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400)),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StatusBadge(status: request.status),
              ),
            ],
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Client + details ──────────────────────────────
                    _SectionCard(
                      title: 'Client',
                      child: Column(children: [
                        _Row('Nom', request.customerName),
                        _Row(
                            'Entreprise', request.companyName ?? 'Particulier'),
                        _Row(
                          'Client',
                          request.inferredClientType == 'b2c'
                              ? 'Particulier'
                              : 'Entreprise',
                        ),
                        _Row(
                          'Type',
                          request.type == RequestType.gift
                              ? 'Cadeau professionnel'
                              : 'Événement',
                          icon: request.type == RequestType.gift
                              ? Icons.card_giftcard_rounded
                              : Icons.event_rounded,
                        ),
                        _Row(
                            'Soumis', AppDateUtils.dateTime(request.createdAt)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    _SectionCard(
                      title: 'Détails',
                      child: Column(
                        children: [
                          ...request.details.entries
                              .where((e) =>
                                  !['note', 'colors', 'services']
                                      .contains(e.key) &&
                                  e.value.toString().isNotEmpty)
                              .map((e) => _Row(
                                    _labelFor(e.key),
                                    e.key == 'eventDate'
                                        ? AppDateUtils.long(
                                            DateTime.parse(e.value))
                                        : _displayValueFor(e.value),
                                  )),
                          if (_hasDisplayValue(request.details['services']))
                            _Row(
                              _labelFor('services'),
                              _displayValueFor(request.details['services']),
                            ),
                          if (_hasDisplayValue(request.details['colors']))
                            _Row(
                              _labelFor('colors'),
                              _displayColors(request.details['colors']),
                            ),
                        ],
                      ),
                    ),
                    // ── Attachments ───────────────────────────────────
                    if (request.attachmentUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _SectionCard(
                        title: 'Fichiers client',
                        child: AttachmentRow(urls: request.attachmentUrls),
                      ),
                    ],
                    // ── Quote sent ────────────────────────────────────
                    if (request.quotedPrice != null) ...[
                      const SizedBox(height: 10),
                      _SectionCard(
                        title: 'Devis envoyé',
                        child: Column(children: [
                          _Row('Prix fournisseur',
                              '${request.supplierPrice?.toStringAsFixed(0) ?? '—'} TND',
                              icon: Icons.lock_outline_rounded),
                          _Row('Prix client',
                              '${request.quotedPrice!.toStringAsFixed(0)} TND',
                              icon: Icons.visibility_outlined),
                          if (request.supplierPrice != null)
                            _Row(
                                'Marge',
                                '${(request.quotedPrice! - request.supplierPrice!).toStringAsFixed(0)} TND'
                                    '  (${((request.quotedPrice! - request.supplierPrice!) / request.supplierPrice! * 100).toStringAsFixed(1)}%)',
                                icon: Icons.trending_up_rounded),
                          if (request.adminNote != null)
                            _Row('Note client', request.adminNote!),
                        ]),
                      ),
                    ],
                    // ── Action buttons ────────────────────────────────
                    const SizedBox(height: 12),
                    _ActionButtons(
                      request: request,
                      onSendQuote: () => _showSendQuoteDialog(request),
                      onReview: () => _updateStatus(
                          request, RequestStatus.reviewing, 'Marquer en revue'),
                      onProduction: () => _updateStatus(request,
                          RequestStatus.inProduction, 'Lancer la production'),
                      onDelivered: () => _updateStatus(request,
                          RequestStatus.delivered, 'Marquer comme livré'),
                      onCancel: () => _updateStatus(request,
                          RequestStatus.cancelled, 'Annuler la commande'),
                    ),
                    // ── Messages ──────────────────────────────────────
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.divider, width: 0.5),
                            ),
                            child: const Center(
                              child: Text('Aucun message.',
                                  style: TextStyle(
                                      color: AppColors.textHint, fontSize: 13)),
                            ),
                          );
                        }
                        return Column(
                          children: msgs
                              .map((m) => _AdminMsgBubble(
                                    message: m,
                                    isAdmin: m.isAdmin,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 72),
                  ],
                ),
              ),
              // ── Message input ─────────────────────────────────────
              Container(
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
                        controller: _msgCtrl,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) =>
                            user != null ? _sendMessage(request, user) : null,
                        decoration: InputDecoration(
                          hintText: 'Répondre au client...',
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
                      onTap: user == null || _sendingMsg
                          ? null
                          : () => _sendMessage(request, user),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                            color: AppColors.lightGold, shape: BoxShape.circle),
                        child: _sendingMsg
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send,
                                color: Colors.white, size: 17),
                      ),
                    ),
                  ]),
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
      'category': 'Catégorie',
      'model': 'Modèle',
      'material': 'Matière',
      'quantity': 'Quantité',
      'eventType': 'Type',
      'eventDate': 'Date',
      'venueType': 'Type de lieu',
      'venueOther': 'Autre lieu',
      'location': 'Lieu',
      'participants': 'Participants',
      'guests': 'Invités',
      'budget': 'Budget',
      'services': 'Services prévus',
      'colors': 'Couleurs',
      'ambiance': 'Ambiance',
      'note': 'Note',
    };
    return map[key] ?? key;
  }

  bool _hasDisplayValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return value.toString().trim().isNotEmpty;
  }

  String _displayValueFor(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).join(', ');
    }
    return value.toString();
  }

  String _displayColors(dynamic value) {
    if (value is! List) return value.toString();
    return value
        .map((item) => _formatColorValue(item))
        .where((item) => item.isNotEmpty)
        .join(', ');
  }

  String _formatColorValue(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';

    final asInt = int.tryParse(raw);
    if (asInt == null) return raw;

    final rgb = asInt & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  double _htToTtc(double ht) => ht * (1 + _tvaRate);

  double _ttcToHt(double ttc) => ttc / (1 + _tvaRate);

  double? _parseAmount(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
}

// ── Margin live preview ────────────────────────────────────────────────────
class _MarginPreview extends StatefulWidget {
  final TextEditingController supplierCtrl, quotedHtCtrl;
  const _MarginPreview({
    required this.supplierCtrl,
    required this.quotedHtCtrl,
  });

  @override
  State<_MarginPreview> createState() => _MarginPreviewState();
}

class _MarginPreviewState extends State<_MarginPreview> {
  @override
  void initState() {
    super.initState();
    widget.supplierCtrl.addListener(_rebuild);
    widget.quotedHtCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.supplierCtrl.removeListener(_rebuild);
    widget.quotedHtCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp =
        double.tryParse(widget.supplierCtrl.text.trim().replaceAll(',', '.'));
    final ht =
        double.tryParse(widget.quotedHtCtrl.text.trim().replaceAll(',', '.'));
    if (sp == null || ht == null || sp == 0) return const SizedBox.shrink();
    final ttc = ht * 1.19;
    final margin = ttc - sp;
    final pct = (margin / sp * 100);
    final positive = margin >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: positive
            ? AppColors.accepted.withValues(alpha: 0.08)
            : AppColors.cancelled.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: positive ? AppColors.accepted : AppColors.cancelled,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'TTC: ${ttc.toStringAsFixed(0)} TND  ·  Marge: ${margin.toStringAsFixed(0)} TND (${pct.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: positive ? AppColors.accepted : AppColors.cancelled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action buttons strip ───────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final QuoteRequest request;
  final VoidCallback onSendQuote, onReview, onProduction, onDelivered, onCancel;

  const _ActionButtons({
    required this.request,
    required this.onSendQuote,
    required this.onReview,
    required this.onProduction,
    required this.onDelivered,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final s = request.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s == RequestStatus.pending)
          OutlinedButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Marquer en revue'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
        if (s == RequestStatus.pending || s == RequestStatus.reviewing) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onSendQuote,
            icon: const Icon(Icons.local_offer_outlined, size: 16),
            label: const Text('Envoyer / Modifier le devis'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
        ],
        if (s == RequestStatus.quoted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pending.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.pending.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.hourglass_top,
                  size: 16, color: AppColors.pending),
              const SizedBox(width: 8),
              const Text('En attente de la réponse du client…',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              TextButton(
                onPressed: onSendQuote,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: const Text('Modifier',
                    style: TextStyle(fontSize: 12, color: AppColors.lightGold)),
              ),
            ]),
          ),
        ],
        if (s == RequestStatus.accepted) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onProduction,
            icon: const Icon(Icons.precision_manufacturing_outlined, size: 16),
            label: const Text('Lancer la production'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.inProduction),
          ),
        ],
        if (s == RequestStatus.inProduction) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onDelivered,
            icon: const Icon(Icons.local_shipping_outlined, size: 16),
            label: const Text('Marquer comme livré'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.delivered),
          ),
        ],
        // Cancel always available unless delivered/cancelled/rejected
        if (![
          RequestStatus.delivered,
          RequestStatus.cancelled,
          RequestStatus.rejected
        ].contains(s)) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined,
                size: 14, color: AppColors.cancelled),
            label: const Text('Annuler la commande',
                style: TextStyle(color: AppColors.cancelled, fontSize: 13)),
          ),
        ],
      ],
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label, value;
  final IconData? icon;
  const _Row(this.label, this.value, {this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: AppColors.navyBlue),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AdminMsgBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isAdmin;
  const _AdminMsgBubble({required this.message, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: 10, left: isAdmin ? 0 : 48, right: isAdmin ? 48 : 0),
      child: Column(
        crossAxisAlignment:
            isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
            child: Text(
              isAdmin ? 'Vous (INWIN)' : message.senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isAdmin ? AppColors.lightGold : AppColors.textHint,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.navyBlue : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isAdmin ? 4 : 16),
                bottomRight: Radius.circular(isAdmin ? 16 : 4),
              ),
              border: isAdmin
                  ? null
                  : Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                  color: isAdmin ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(
              AppDateUtils.time(message.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
