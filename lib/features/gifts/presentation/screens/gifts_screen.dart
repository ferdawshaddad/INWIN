import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';

const _categories = [
  {
    'id': 'carnet',
    'label': 'Cahier',
    'sub': 'Personnalisé avec votre logo',
    'image': 'assets/images/notebook canvas.png'
  },
  {
    'id': 'gourdes_mug',
    'label': 'Gourdes & Mugs',
    'sub': 'Inox, céramique, bambou',
    'image': 'assets/images/cup canvas.png'
  },
  {
    'id': 'porte_cles',
    'label': 'Porte-clés',
    'sub': 'Métal, cuir, gravé',
    'image': 'assets/images/key chain canvas.png'
  },
  {
    'id': 'stylos',
    'label': 'Stylos',
    'sub': 'Premium & personnalisés',
    'image': 'assets/images/pen canvas.png'
  },
  {
    'id': 'sacs',
    'label': 'Tote bag',
    'sub': 'Toile, coton, recyclé',
    'image': 'assets/images/bag canvas.png'
  },
  {
    'id': 'coffrets',
    'label': 'Coffrets cadeaux',
    'sub': 'Assortiments sur mesure',
    'image': 'assets/images/coffret canvas.png'
  },
];

class GiftsScreen extends StatelessWidget {
  const GiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Cadeaux')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          return _CategoryCard(
            id: cat['id']!,
            label: cat['label']!,
            sub: cat['sub']!,
            image: cat['image']!,
            onTap: () => context.go('/gifts/${cat['id']}'),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String id, label, sub, image;
  final VoidCallback onTap;
  const _CategoryCard(
      {required this.id,
      required this.label,
      required this.sub,
      required this.image,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
