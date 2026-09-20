import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';

// ─── Data model ────────────────────────────────────────────────────────────
class ClientRealisation {
  final String clientName;
  final String logoAssetOrUrl; // asset path or https:// URL
  final List<String> productImageUrls; // List of images (assets or URLs)
  final String description;
  final String targetCategoryId;
  final String? linkUrl;

  const ClientRealisation({
    required this.clientName,
    required this.logoAssetOrUrl,
    required this.productImageUrls,
    required this.description,
    required this.targetCategoryId,
    this.linkUrl,
  });
}

// ─── Showcase data ─────────────────────────────────────────────────────────
final _realisations = [
  const ClientRealisation(
    clientName: 'Faculté de Médecine de Tunis',
    logoAssetOrUrl: 'assets/images/logo fmt.png',
    productImageUrls: [
      'assets/images/Faculté de medecine coffret.png',
      'assets/images/fmt cle.png',
      'assets/images/fmt pencil.png',
      'assets/images/notebook fmt.png',
    ],
    description: 'Coffret cahier + stylo + porte-clés gravé',
    targetCategoryId: 'coffrets',
  ),
  const ClientRealisation(
    clientName: 'Délice',
    logoAssetOrUrl: 'assets/images/delice logo.webp',
    productImageUrls: [
      'assets/images/tote bag delice.png',
    ],
    description: 'Tote bags personnalisés',
    targetCategoryId: 'sacs',
  ),
];

// ─── Section widget ────────────────────────────────────────────────────────
class TrustedClientsSection extends StatefulWidget {
  const TrustedClientsSection({super.key});

  @override
  State<TrustedClientsSection> createState() => _TrustedClientsSectionState();
}

class _TrustedClientsSectionState extends State<TrustedClientsSection> {
  final _ctrl = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Text(
            'Nous fait confiance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _realisations.length,
            itemBuilder: (ctx, i) => _RealisationCard(
              item: _realisations[i],
              isActive: _page == i,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_realisations.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _page == i ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _page == i ? AppColors.navyBlue : AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Single carousel card ──────────────────────────────────────────────────
class _RealisationCard extends StatelessWidget {
  final ClientRealisation item;
  final bool isActive;
  const _RealisationCard({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final thumb = item.productImageUrls.first;
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isActive ? 1.0 : 0.97,
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppColors.navyBlue.withValues(alpha: 0.18)
                  : AppColors.divider,
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _SmartImage(url: thumb, width: 120, height: 120),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ClientLogo(url: item.logoAssetOrUrl),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.photo_library_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        item.productImageUrls.length == 1
                            ? '1 photo'
                            : '${item.productImageUrls.length} photos',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openDetail(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Découvrir',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RealisationDetailSheet(item: item),
    );
  }
}

// ─── Detail bottom sheet with Gallery ──────────────────────────────────────
class _RealisationDetailSheet extends StatefulWidget {
  final ClientRealisation item;
  const _RealisationDetailSheet({required this.item});

  @override
  State<_RealisationDetailSheet> createState() =>
      _RealisationDetailSheetState();
}

class _RealisationDetailSheetState extends State<_RealisationDetailSheet> {
  final _imgCtrl = PageController();
  int _imgPage = 0;

  @override
  void dispose() {
    _imgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.item.productImageUrls;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Gallery Carousel ────────────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: _imgCtrl,
                  onPageChanged: (i) => setState(() => _imgPage = i),
                  itemCount: imgs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _SmartImage(
                          url: imgs[i], width: double.infinity, height: 280),
                    ),
                  ),
                ),
              ),
              if (_imgPage > 0)
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryArrow(
                      icon: Icons.chevron_left,
                      onTap: () => _imgCtrl.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                ),
              if (_imgPage < imgs.length - 1)
                Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryArrow(
                      icon: Icons.chevron_right,
                      onTap: () => _imgCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                ),
              if (imgs.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imgs.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _imgPage == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _imgPage == i ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),

          // ── Thumbnail strip ─────────────────────────────────────
          if (imgs.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: imgs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _imgPage == i;
                  return GestureDetector(
                    onTap: () => _imgCtrl.animateToPage(i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              active ? AppColors.navyBlue : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _SmartImage(url: imgs[i], width: 60, height: 60),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Client details ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              _ClientLogo(url: widget.item.logoAssetOrUrl, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.clientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              widget.item.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close the bottom sheet
                context.push('/gifts/${widget.item.targetCategoryId}');
              },
              icon: const Icon(Icons.star_outline, size: 16),
              label: const Text('Demander un projet similaire'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────

class _GalleryArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GalleryArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration:
            const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SmartImage extends StatelessWidget {
  final String url;
  final double? width, height;

  const _SmartImage({
    required this.url,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isAsset = !url.startsWith('http');
    if (isAsset) {
      return Image.asset(url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorPlaceholder());
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => _loadingPlaceholder(),
      errorWidget: (_, __, ___) => _errorPlaceholder(),
    );
  }

  Widget _loadingPlaceholder() => Container(
      width: width,
      height: height,
      color: AppColors.surface,
      child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.navyBlue)));

  Widget _errorPlaceholder() => Container(
      width: width,
      height: height,
      color: AppColors.surface,
      child: const Icon(Icons.image_outlined,
          size: 32, color: AppColors.textHint));
}

class _ClientLogo extends StatelessWidget {
  final String url;
  final double height;
  const _ClientLogo({required this.url, this.height = 38});

  @override
  Widget build(BuildContext context) {
    final isNetwork = url.startsWith('http');
    return SizedBox(
      height: height,
      child: isNetwork
          ? CachedNetworkImage(
              imageUrl: url,
              height: height,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                height: height,
                width: height * 2.2,
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.business,
                    size: 20, color: AppColors.navyBlue),
              ),
            )
          : Image.asset(url, height: height, fit: BoxFit.contain),
    );
  }
}
