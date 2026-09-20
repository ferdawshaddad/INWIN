import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_theme.dart';

/// Displays a row of attachment thumbnails.
/// Tapping opens a full-screen viewer.
class AttachmentRow extends StatelessWidget {
  final List<String> urls;

  const AttachmentRow({super.key, required this.urls});

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp');
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final url = urls[i];
          return GestureDetector(
            onTap: () => _isImage(url)
                ? _openImageViewer(ctx, url, urls.where(_isImage).toList())
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _isImage(url)
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 76, height: 76,
                        color: AppColors.surface,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _FileThumbnail(url: url),
                    )
                  : _FileThumbnail(url: url),
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(BuildContext context, String current, List<String> images) {
    final initialIndex = images.indexOf(current);
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ImageViewerScreen(
        images: images,
        initialIndex: initialIndex,
      ),
    ));
  }
}

class _FileThumbnail extends StatelessWidget {
  final String url;
  const _FileThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76, height: 76,
      decoration: BoxDecoration(
        color: AppColors.navyBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 28, color: AppColors.navyBlue),
          const SizedBox(height: 4),
          Text(
            url.split('.').last.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.navyBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _ImageViewerScreen({required this.images, required this.initialIndex});

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        onPageChanged: (i) => setState(() => _current = i),
        itemCount: widget.images.length,
        itemBuilder: (ctx, i) => InteractiveViewer(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
