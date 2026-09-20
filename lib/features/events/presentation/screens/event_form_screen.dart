import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';
import '../../../../core/widgets/inwin_button.dart';
import '../../../../core/widgets/inwin_color_picker.dart';
import '../../../../core/widgets/inwin_text_field.dart';

const _eventTitles = {
  'seminaire': 'Séminaire',
  'team_building': 'Team Building',
  'lancement_produit': 'Lancement Produit',
  'conference': 'Conférence',
  'inauguration': 'Inauguration',
  'fete_annuelle': 'Fête Annuelle',
};

const _ambiances = [
  'Professionnel',
  'Festif',
  'VIP / Prestige',
  'Décontracté',
  'Créatif',
];

const _corporateColors = [
  {'name': 'Bleu Marine', 'color': Color(0xFF1A237E)},
  {'name': 'Gris Anthracite', 'color': Color(0xFF263238)},
  {'name': 'Or / Prestige', 'color': Color(0xFFD4A853)},
  {'name': 'Argent / Blanc', 'color': Color(0xFFE0E0E0)},
  {'name': 'Bordeaux', 'color': Color(0xFF880E4F)},
  {'name': 'Bleu Royal', 'color': Color(0xFF0D47A1)},
];

const _venueOptions = [
  'Hôtel',
  'Salle de conférence',
  'Espace coworking',
  'Plein air',
  "Dans les locaux de l'entreprise",
  'Autre',
];

const _participantRanges = [
  'Moins de 20',
  '20 - 50',
  '50 - 100',
  '100 - 300',
  'Plus de 300',
];

const _budgetOptions = [
  'Moins de 2 000 TND',
  '2 000 - 5 000 TND',
  '5 000 - 10 000 TND',
  'Flexible',
];

const _serviceOptions = [
  'Décoration',
  'Restauration',
  'Photographie / Vidéo',
  'Sonorisation',
  'Animation',
  'Éclairage',
  'Scène / Podium',
  'Mobilier',
  'Signalétique / Impression',
  'Accueil & Hôtesses',
  'Sécurité',
  'Transport / Navettes',
  'Cadeaux / Goodies',
  'Streaming / Live',
  'Coordination événementielle',
  'Autre',
];

class EventFormScreen extends ConsumerStatefulWidget {
  final String eventType;
  const EventFormScreen({super.key, required this.eventType});

  @override
  ConsumerState<EventFormScreen> createState() => _State();
}

class _State extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _otherVenueCtrl = TextEditingController();
  final _otherServiceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime? _eventDate;
  final _selectedColors = <Color>{};
  final _selectedServices = <String>{};
  String _ambiance = _ambiances.first;
  String _venueType = _venueOptions.first;
  String _participantRange = _participantRanges[1];
  String _budget = _budgetOptions[1];
  bool _loading = false;

  bool get _needsOtherVenue => _venueType == 'Autre';
  bool get _needsOtherService => _selectedServices.contains('Autre');

  @override
  void dispose() {
    _locationCtrl.dispose();
    _otherVenueCtrl.dispose();
    _otherServiceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.navyBlue),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _eventDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une date.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull!;
      final services = _selectedServices
          .where((service) => service != 'Autre')
          .toList()
        ..sort();
      if (_needsOtherService && _otherServiceCtrl.text.trim().isNotEmpty) {
        services.add('Autre: ${_otherServiceCtrl.text.trim()}');
      }

      final req = QuoteRequest(
        id: '',
        customerId: user.uid,
        customerName: user.fullName,
        companyName: user.companyName,
        type: RequestType.event,
        status: RequestStatus.pending,
        details: {
          'clientType': user.clientType.name,
          'eventType': _eventTitles[widget.eventType] ?? widget.eventType,
          'eventDate': _eventDate!.toIso8601String(),
          'venueType': _venueType,
          'location': _locationCtrl.text.trim(),
          'participants': _participantRange,
          'budget': _budget,
          'services': services,
          'colors':
              _selectedColors.map((c) => c.toARGB32().toString()).toList(),
          'ambiance': _ambiance,
          'note': _noteCtrl.text.trim(),
          if (_needsOtherVenue && _otherVenueCtrl.text.trim().isNotEmpty)
            'venueOther': _otherVenueCtrl.text.trim(),
        },
        attachmentUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(requestServiceProvider).createRequest(req);
      if (mounted) _showSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
        if (service == 'Autre') {
          _otherServiceCtrl.clear();
        }
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accepted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.accepted,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Demande envoyée !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notre équipe va analyser votre demande et vous recontactera rapidement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/projects');
              },
              child: const Text('Voir mes projets'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_eventTitles[widget.eventType] ?? 'Événement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _Label("Date de l'événement"),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.navyBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _eventDate == null
                            ? 'Sélectionner une date'
                            : DateFormat('dd/MM/yyyy').format(_eventDate!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _eventDate == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_eventDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _eventDate = null),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _Label('Lieu'),
            const SizedBox(height: 4),
            const Text(
              'Définit le cadre physique de votre événement.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 10),
            _ChoiceWrap<String>(
              options: _venueOptions,
              selected: {_venueType},
              onTap: (value) {
                setState(() {
                  _venueType = value;
                  if (value != 'Autre') {
                    _otherVenueCtrl.clear();
                  }
                });
              },
            ),
            if (_needsOtherVenue) ...[
              const SizedBox(height: 10),
              InwinTextField(
                label: 'Autre type de lieu',
                hint: 'Ex: showroom, plage privée, rooftop...',
                controller: _otherVenueCtrl,
                validator: (value) =>
                    _needsOtherVenue && (value == null || value.trim().isEmpty)
                        ? 'Précisez le type de lieu'
                        : null,
              ),
            ],
            const SizedBox(height: 10),
            InwinTextField(
              label: 'Localisation exacte',
              hint: 'Adresse, ville, hôtel, site exact...',
              controller: _locationCtrl,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Adresse requise'
                  : null,
              prefix: const Icon(Icons.location_on_outlined, size: 20),
            ),
            const SizedBox(height: 20),
            const _Label('Nombre de participants'),
            const SizedBox(height: 4),
            const Text(
              'Quantifie la taille de la demande.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 10),
            _ChoiceWrap<String>(
              options: _participantRanges,
              selected: {_participantRange},
              onTap: (value) => setState(() => _participantRange = value),
            ),
            const SizedBox(height: 20),
            const _Label('Budget (TND)'),
            const SizedBox(height: 4),
            const Text(
              'Fixe les attentes budgétaires du projet.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 10),
            _ChoiceWrap<String>(
              options: _budgetOptions,
              selected: {_budget},
              onTap: (value) => setState(() => _budget = value),
            ),
            const SizedBox(height: 20),
            const _Label('Services souhaités'),
            const SizedBox(height: 4),
            const Text(
              'Sélectionnez les prestations utiles. La description reste optionnelle.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 10),
            _ChoiceWrap<String>(
              options: _serviceOptions,
              selected: _selectedServices,
              multiSelect: true,
              onTap: _toggleService,
            ),
            if (_needsOtherService) ...[
              const SizedBox(height: 10),
              InwinTextField(
                label: 'Autre service',
                hint: 'Précisez le service souhaité',
                controller: _otherServiceCtrl,
                validator: (value) => _needsOtherService &&
                        (value == null || value.trim().isEmpty)
                    ? 'Précisez le service'
                    : null,
              ),
            ],
    const SizedBox(height: 20),
            const _Label("Couleurs de l'événement"),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _corporateColors.map((item) {
                final color = item['color'] as Color;
                final name = item['name'] as String;
                final selected = _selectedColors.contains(color);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedColors.remove(color);
                    } else {
                      _selectedColors.add(color);
                    }
                  }),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppColors.gold
                                : Colors.black12,
                            width: selected ? 3 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? AppColors.navyBlue : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            InwinColorPicker(
              onColorChanged: (color) {
                setState(() {
                  _selectedColors.add(color);
                });
              },
            ),
            const SizedBox(height: 20),
            const _Label("L'ambiance"),
            const SizedBox(height: 10),
            _ChoiceWrap<String>(
              options: _ambiances,
              selected: {_ambiance},
              onTap: (value) => setState(() => _ambiance = value),
            ),
            const SizedBox(height: 20),
            const _Label('Description & souhaits (optionnel)'),
            const SizedBox(height: 10),
            InwinTextField(
              label: 'Ex: thème, contraintes, détails pratiques...',
              controller: _noteCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            InwinButton(label: 'VALIDER', onTap: _submit, loading: _loading),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.navyBlue,
        ),
      );
}

class _ChoiceWrap<T> extends StatelessWidget {
  final List<T> options;
  final Set<T> selected;
  final ValueChanged<T> onTap;
  final bool multiSelect;

  const _ChoiceWrap({
    required this.options,
    required this.selected,
    required this.onTap,
    this.multiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxChipWidth = MediaQuery.sizeOf(context).width - 40;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onTap(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.navyBlue.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.navyBlue : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        multiSelect
                            ? Icons.check_circle
                            : Icons.radio_button_checked,
                        size: 16,
                        color: AppColors.navyBlue,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      option.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
