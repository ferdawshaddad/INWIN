import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/models/quote_request.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/request_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/inwin_button.dart';
import '../../../../core/widgets/inwin_text_field.dart';
import '../widgets/logo_positioner.dart';

const _configs = {
  'carnet': {
    'title': 'Cahier',
    'models': [
      'Cahier Standard (A5)',
      'Cahier Premium (A4)',
      'Cahier Pocket (A6)',
    ],
    'materials': [
      'Couverture Cartonnée',
      'Carton Rigide',
      'Couverture Tissu',
      'Simili Cuir',
    ],
  },
  'gourdes_mug': {
    'title': 'Gourdes & Mugs',
    'models': [
      'Mug 250ml',
      'Mug 500ml',
    ],
    'materials': [
      'Céramique',
      'Mug Magique',
      'Poterie',
    ],
  },
  'porte_cles': {
    'title': 'Porte-cles',
    'models': [
      'Porte-cles Rond',
      'Porte-cles Rectangle',
    ],
    'materials': [
      'Le Métal',
      'Le Similicuir',
      'Le Bois',
      'Le Plastique',
    ],
  },
  'stylos': {
    'title': 'Stylos',
    'models': [
      'Standard',
    ],
    'materials': [
      'Plastique',
      'Métal',
      'Bois',
    ],
  },
  'sacs': {
    'title': 'Tote bag',
    'models': [
      'Standard',
    ],
    'materials': [
      'Coton',
    ],
  },
  'coffrets': {
    'title': 'Coffrets cadeaux',
    'models': [
      'Standard',
    ],
    'materials': [
      'Carton Rigide',
      'Bois',
      'Plastique',
    ],
  },
};

const _materialPhotos = {
  'Couverture Cartonnée': 'assets/images/notebook cover carton (Couverture Cartonnée).png',
  'Carton Rigide': 'assets/images/notebook cover carton rigid.png',
  'Couverture Tissu': 'assets/images/notebook cover cloth (Couverture tissu).png',
  'Simili Cuir': 'assets/images/notebook cover cuir (Simili cuir).jpg',
};

Map<String, dynamic> _configFor(String cat) {
  return _configs[cat] ??
      {
        'title': cat,
        'models': ['Standard'],
        'materials': ['Standard'],
      };
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class GiftConfiguratorScreen extends ConsumerStatefulWidget {
  final String category;

  const GiftConfiguratorScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<GiftConfiguratorScreen> createState() => _State();
}

class _State extends ConsumerState<GiftConfiguratorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedModel;
  late String _selectedMaterial;
  final _qtyCtrl = TextEditingController(text: '50');
  final _noteCtrl = TextEditingController();

  PlatformFile? _file;
  File? _logoImageFile;
  LogoPosition _logoPosition = const LogoPosition();
  Map<String, LogoPosition> _logoPositions = {};
  Map<String, Color> _productColors = {};
  bool _loading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    final cfg = _configFor(widget.category);
    _selectedModel = (cfg['models'] as List).first.toString();
    _selectedMaterial = (cfg['materials'] as List).first.toString();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'ai', 'svg'],
    );
    if (result == null) return;

    final picked = result.files.first;
    final extension = picked.extension?.toLowerCase();
    final isImage = extension == 'jpg' || extension == 'jpeg' || extension == 'png';

    setState(() {
      _file = picked;
      _logoImageFile = isImage && picked.path != null ? File(picked.path!) : null;
      _logoPosition = const LogoPosition();
      _logoPositions = {};
      _productColors = {};
    });
  }

  void _clearFile() {
    setState(() {
      _file = null;
      _logoImageFile = null;
      _logoPosition = const LogoPosition();
      _logoPositions = {};
      _productColors = {};
      _uploadProgress = 0;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_file == null || _file?.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez joindre votre logo ou fichier de marquage.'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _uploadProgress = 0;
    });

    try {
      final user = ref.read(currentUserProvider).valueOrNull!;
      final url = await ref.read(storageServiceProvider).uploadFile(
        file: File(_file!.path!),
        folder: 'markings/${user.uid}',
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress);
        },
      );

      final details = <String, dynamic>{
        'clientType': user.clientType.name,
        'category': _configFor(widget.category)['title'],
        'model': _selectedModel,
        'material': _selectedMaterial,
        'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
        'note': _noteCtrl.text.trim(),
        'logoFileName': _file!.name,
        'logoFileType': _file!.extension?.toLowerCase(),
        'hasInteractivePositioning': _logoImageFile != null,
      };

      if (_logoImageFile != null) {
        if (widget.category == 'coffrets') {
          details['logoPositions'] = _logoPositions.map(
            (key, pos) => MapEntry(key, pos.toMap()),
          );
        } else {
          details['logoPosition'] = _logoPosition.toMap();
        }

        if (_productColors.isNotEmpty) {
          details['productColors'] = _productColors.map(
            (key, color) => MapEntry(key, _colorToHex(color)),
          );
        }
      }

      final req = QuoteRequest(
        id: '',
        customerId: user.uid,
        customerName: user.fullName,
        companyName: user.companyName,
        type: RequestType.gift,
        status: RequestStatus.pending,
        details: details,
        attachmentUrls: [url],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(requestServiceProvider).createRequest(req);
      if (mounted) _showSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.cancelled,
        ),
      );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
              'Demande envoyee !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre demande a bien ete recue. Notre equipe vous contactera avec un devis sous 24-48h.',
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
    final cfg = _configFor(widget.category);
    final models = cfg['models'] as List;
    final materials = cfg['materials'] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cfg['title'].toString().toUpperCase(),
          style: const TextStyle(letterSpacing: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (models.length > 1) ...[
              const _SectionLabel('Choix du modele de base'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedModel,
                decoration: const InputDecoration(labelText: 'Modele'),
                items: models
                    .map(
                      (model) => DropdownMenuItem<String>(
                        value: model.toString(),
                        child: Text(model.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedModel = value);
                },
              ),
              const SizedBox(height: 20),
            ],
            if (materials.length > 1) ...[
              const _SectionLabel('Matiere'),
              const SizedBox(height: 10),
              if (widget.category == 'carnet')
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: materials.length,
                    itemBuilder: (context, index) {
                      final material = materials[index].toString();
                      final photo = _materialPhotos[material];
                      final selected = _selectedMaterial == material;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedMaterial = material),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.navyBlue : AppColors.divider,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (selected)
                                BoxShadow(
                                  color: AppColors.navyBlue.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10),
                                  ),
                                  child: photo != null
                                      ? Image.asset(photo, fit: BoxFit.cover)
                                      : Container(color: Colors.grey[200]),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  material,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected ? AppColors.navyBlue : AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: materials.map((material) {
                    final materialValue = material.toString();
                    final selected = _selectedMaterial == materialValue;
                    return ChoiceChip(
                      label: Text(materialValue),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedMaterial = materialValue);
                      },
                      selectedColor: AppColors.navyBlue,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
            const _SectionLabel('Quantite souhaitee'),
            const SizedBox(height: 10),
            InwinTextField(
              label: 'Quantite',
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              validator: (value) {
                final quantity = int.tryParse(value ?? '');
                if (quantity == null || quantity < 1) {
                  return 'Quantite invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Votre marquage / logo'),
            const SizedBox(height: 10),
            _LogoUploadBox(
              file: _file,
              logoImageFile: _logoImageFile,
              uploadProgress: _uploadProgress,
              isUploading: _loading,
              onTap: _pickFile,
              onClear: _clearFile,
            ),
            if (_logoImageFile != null) ...[
              const SizedBox(height: 24),
              LogoPositioner(
                logoFile: _logoImageFile!,
                category: widget.category,
                initialPosition: _logoPosition,
                initialPositions: _logoPositions,
                initialProductColors: _productColors,
                selectedMaterial: _selectedMaterial,
                onChanged: (position) {
                  setState(() => _logoPosition = position);
                },
                onPositionsChanged: (positions) {
                  setState(() => _logoPositions = positions);
                },
                onProductColorsChanged: (colors) {
                  setState(() => _productColors = colors);
                },
              ),
            ]
else if (_file != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Le positionnement interactif est disponible pour les fichiers JPG et PNG. Les PDF, AI et SVG seront bien envoyes a votre equipe.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const _SectionLabel('Note supplementaire (optionnel)'),
            const SizedBox(height: 10),
            InwinTextField(
              label: 'Ex: couleurs specifiques, finition doree...',
              controller: _noteCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            InwinButton(
              label: 'VALIDER',
              onTap: _submit,
              loading: _loading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LogoUploadBox extends StatelessWidget {
  final PlatformFile? file;
  final File? logoImageFile;
  final double uploadProgress;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _LogoUploadBox({
    required this.file,
    required this.logoImageFile,
    required this.uploadProgress,
    required this.isUploading,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: file == null ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.accepted : AppColors.divider,
            width: file != null ? 1.5 : 0.5,
          ),
        ),
        child: file == null
            ? const _EmptyUpload()
            : _FilledUpload(
                file: file!,
                logoImageFile: logoImageFile,
                uploadProgress: uploadProgress,
                isUploading: isUploading,
                onClear: onClear,
                onReplace: onTap,
              ),
      ),
    );
  }
}

class _EmptyUpload extends StatelessWidget {
  const _EmptyUpload();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          size: 36,
          color: AppColors.navyBlue,
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Cliquez pour telecharger ',
                style: TextStyle(
                  color: AppColors.navyBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: 'ou glisser-deposer',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'JPEG, PNG -> positionnement interactif  |  PDF, AI, SVG -> envoi simple',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FilledUpload extends StatelessWidget {
  final PlatformFile file;
  final File? logoImageFile;
  final double uploadProgress;
  final bool isUploading;
  final VoidCallback onClear;
  final VoidCallback onReplace;

  const _FilledUpload({
    required this.file,
    required this.logoImageFile,
    required this.uploadProgress,
    required this.isUploading,
    required this.onClear,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: logoImageFile != null
                  ? Image.file(
                      logoImageFile!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: AppColors.accepted.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.accepted,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${(file.size / 1024).toStringAsFixed(0)} KB${logoImageFile != null ? '  |  Positionnement disponible' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              Column(
                children: [
                  Text(
                    '${(uploadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.navyBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      value: uploadProgress,
                      backgroundColor: AppColors.divider,
                      color: AppColors.navyBlue,
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.swap_horiz,
                      size: 18,
                      color: AppColors.navyBlue,
                    ),
                    tooltip: 'Remplacer',
                    onPressed: onReplace,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    tooltip: 'Supprimer',
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
        if (isUploading) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: uploadProgress,
              minHeight: 5,
              backgroundColor: AppColors.divider,
              color: AppColors.navyBlue,
            ),
          ),
        ],
      ],
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
