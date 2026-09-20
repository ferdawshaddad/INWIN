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

const _b2cEventTitles = {
  'bride_to_be': 'Bride to be',
  'anniversaire': 'Anniversaire',
  'fete_traditionnelle': 'Fête traditionnelle',
  'baby_shower': 'Baby shower',
  'fiancailles': 'Fiançailles',
  'fete_privee': 'Soirée privée',
};

const _b2cAtmospheres = [
  'Élégant',
  'Chaleureux',
  'Festif',
  'Romantique',
  'Moderne',
];

const _b2cColors = [
  {'name': 'Rose Poudré', 'color': Color(0xFFFFD1DC)},
  {'name': 'Or', 'color': Color(0xFFD4A853)},
  {'name': 'Bleu Marine', 'color': Color(0xFF1A237E)},
  {'name': 'Blanc Pur', 'color': Color(0xFFFFFFFF)},
  {'name': 'Vert Sauge', 'color': Color(0xFFB2AC88)},
  {'name': 'Terracotta', 'color': Color(0xFFE2725B)},
];

const _b2cServices = [
  'Traiteur',
  'Décoration',
  'DJ / Animation',
  'Photographe',
  'Gâteau / Sweets',
  'Accueil',
];

const _b2cBudgets = [
  'Moins de 1 000 TND',
  '1 000 - 3 000 TND',
  '3 000 - 5 000 TND',
  'Plus de 5 000 TND',
];

class B2cEventFormScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const B2cEventFormScreen({
    super.key,
    this.initialCategory,
  });

  @override
  ConsumerState<B2cEventFormScreen> createState() => _B2cEventFormScreenState();
}

class _B2cEventFormScreenState extends ConsumerState<B2cEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController(text: '30');
  final _noteCtrl = TextEditingController();

  late String _eventType;
  late String _atmosphere;
  late String _budget;
  DateTime? _eventDate;
  bool _loading = false;

  // New fields
  final List<String> _selectedServices = [];
  final List<String> _selectedColors = [];
  bool _isExternalLocation = true;

  @override
  void initState() {
    super.initState();
    _eventType = _normalizeCategory(widget.initialCategory);
    _atmosphere = _b2cAtmospheres.first;
    _budget = _b2cBudgets[1];
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _guestsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _normalizeCategory(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (_b2cEventTitles.containsKey(value)) {
      return value!;
    }
    return 'anniversaire';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 21)),
      firstDate: DateTime.now().add(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.navyBlue),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _eventDate = picked);
    }
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
      final request = QuoteRequest(
        id: '',
        customerId: user.uid,
        customerName: user.fullName,
        companyName: null,
        type: RequestType.event,
        status: RequestStatus.pending,
        details: {
          'clientType': 'b2c',
          'eventType': _b2cEventTitles[_eventType]!,
          'eventDate': _eventDate!.toIso8601String(),
          'locationType': _isExternalLocation ? 'Lieu externe' : 'Domicile',
          'location': _locationCtrl.text.trim(),
          'guests': _guestsCtrl.text.trim(),
          'budget': _budget,
          'ambiance': _atmosphere,
          'services': _selectedServices,
          'colors': _selectedColors,
          'note': _noteCtrl.text.trim(),
        },
        attachmentUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(requestServiceProvider).createRequest(request);
      if (mounted) _showSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
              'Votre événement personnel a bien été transmis. L’équipe INWIN vous recontactera rapidement.',
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Événement personnel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parlez-nous de votre projet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nous préparons une proposition sur mesure selon votre occasion, votre lieu et votre budget.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel("Type d'événement"),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _eventType,
              decoration: const InputDecoration(labelText: 'Occasion'),
              items: _b2cEventTitles.entries
                  .map((entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _eventType = value);
                }
              },
            ),
            const SizedBox(height: 20),
            const _SectionLabel("Date de l'événement"),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.navyBlue),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel("Lieu de l'événement"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isExternalLocation = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isExternalLocation ? AppColors.navyBlue : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mon Domicile',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: !_isExternalLocation ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isExternalLocation = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isExternalLocation ? AppColors.navyBlue : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Lieu Externe',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _isExternalLocation ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isExternalLocation) ...[
              const SizedBox(height: 16),
              InwinTextField(
                label: 'Lieu souhaité',
                hint: 'Salle, villa, restaurant...',
                controller: _locationCtrl,
                validator: (value) =>
                    (_isExternalLocation && (value == null || value.trim().isEmpty)) ? 'Champ requis' : null,
                prefix: const Icon(Icons.location_on_outlined, size: 20),
              ),
            ],
            const SizedBox(height: 20),
            const _SectionLabel('Nombre d’invités'),
            const SizedBox(height: 10),
            InwinTextField(
              label: 'Nombre d’invités',
              controller: _guestsCtrl,
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (int.tryParse(value ?? '') ?? 0) < 1 ? 'Nombre invalide' : null,
              prefix: const Icon(Icons.groups_outlined, size: 20),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Budget estimatif'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _budget,
              decoration: const InputDecoration(labelText: 'Budget'),
              items: _b2cBudgets
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _budget = value);
                }
              },
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Ambiance souhaitée'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _b2cAtmospheres.map((atm) {
                final isSelected = _atmosphere == atm;
                return ChoiceChip(
                  label: Text(atm),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _atmosphere = atm);
                  },
                  selectedColor: AppColors.navyBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Couleurs du thème'),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _b2cColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final colorData = _b2cColors[i];
                  final name = colorData['name'] as String;
                  final color = colorData['color'] as Color;
                  final isSelected = _selectedColors.contains(name);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedColors.remove(name);
                        } else {
                          _selectedColors.add(name);
                        }
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.navyBlue : AppColors.divider,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppColors.navyBlue.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            InwinColorPicker(
              onColorChanged: (color) {
                final hex = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                setState(() {
                  if (!_selectedColors.contains(hex)) {
                    _selectedColors.add(hex);
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Services souhaités'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: _b2cServices.map((service) {
                final isSelected = _selectedServices.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                  selectedColor: AppColors.lightGold.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.lightGold,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.darkGold : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            InwinTextField(
              label: 'Précisions (optionnel)',
              hint: 'Décoration, thème, restauration, animation...',
              controller: _noteCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            InwinButton(
              label: 'VALIDER',
              onTap: _submit,
              loading: _loading,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.navyBlue,
      ),
    );
  }
}
