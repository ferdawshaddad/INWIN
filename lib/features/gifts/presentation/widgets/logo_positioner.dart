import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_theme.dart';

import '../../../../core/widgets/inwin_color_picker.dart';

class LogoPosition {
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final String? subCategory;

  const LogoPosition({
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 0.3,
    this.rotation = 0.0,
    this.subCategory,
  });

  LogoPosition copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    String? subCategory,
  }) {
    return LogoPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      subCategory: subCategory ?? this.subCategory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
      'space': 'print_area',
      'version': 2,
      if (subCategory != null) 'subCategory': subCategory,
    };
  }
}

class LogoPositioner extends StatefulWidget {
  final File logoFile;
  final String category;
  final LogoPosition initialPosition;
  final Map<String, LogoPosition>? initialPositions;
  final ValueChanged<LogoPosition> onChanged;
  final ValueChanged<Map<String, LogoPosition>>? onPositionsChanged;
  final Map<String, Color>? initialProductColors;
  final ValueChanged<Map<String, Color>>? onProductColorsChanged;
  final String? selectedMaterial;

  const LogoPositioner({
    super.key,
    required this.logoFile,
    required this.category,
    required this.onChanged,
    this.initialPosition = const LogoPosition(),
    this.initialPositions,
    this.onPositionsChanged,
    this.initialProductColors,
    this.onProductColorsChanged,
    this.selectedMaterial,
  });

  @override
  State<LogoPositioner> createState() => _LogoPositionerState();
}

class _LogoPositionerState extends State<LogoPositioner> {
  late LogoPosition _position;
  late Map<String, LogoPosition> _positions;
  late Map<String, Color> _productColors;
  Offset? _gestureStartFocalPoint;
  LogoPosition? _positionAtGestureStart;
  _PreviewMetrics? _metrics;
  double _logoAspectRatio = 1.0;
  String _coffretSubCategory = 'notebook';

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _positions = widget.initialPositions ?? {};
    _productColors = {
      ..._defaultProductColorsFor(widget.category),
      if (widget.category == 'coffrets') ...{
        ..._defaultProductColorsFor('coffret_notebook'),
        ..._defaultProductColorsFor('coffret_pen'),
        ..._defaultProductColorsFor('coffret_keychain'),
      },
      ...?widget.initialProductColors,
    };
    _loadLogoAspectRatio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onProductColorsChanged?.call(_productColors);
      if (widget.category == 'coffrets') {
        widget.onPositionsChanged?.call(_positions);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LogoPositioner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoFile.path != widget.logoFile.path) {
      _position = widget.initialPosition;
      _positions = widget.initialPositions ?? {};
      _logoAspectRatio = 1.0;
      _loadLogoAspectRatio();
    }
    if (oldWidget.category != widget.category) {
      _productColors = {
        ..._defaultProductColorsFor(widget.category),
        if (widget.category == 'coffrets') ...{
          ..._defaultProductColorsFor('coffret_notebook'),
          ..._defaultProductColorsFor('coffret_pen'),
          ..._defaultProductColorsFor('coffret_keychain'),
        },
        ...?widget.initialProductColors,
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onProductColorsChanged?.call(_productColors);
      });
    }
  }

  Future<void> _loadLogoAspectRatio() async {
    final path = widget.logoFile.path;

    try {
      final bytes = await widget.logoFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final ratio = image.width > 0 && image.height > 0
          ? image.width / image.height
          : 1.0;
      image.dispose();

      if (!mounted || widget.logoFile.path != path) return;
      setState(() => _logoAspectRatio = ratio);
    } catch (_) {
      if (!mounted || widget.logoFile.path != path) return;
      setState(() => _logoAspectRatio = 1.0);
    }
  }

  void _emit(LogoPosition next) {
    if (widget.category == 'coffrets') {
      setState(() {
        _positions = {
          ..._positions,
          _coffretSubCategory: next.copyWith(subCategory: _coffretSubCategory),
        };
      });
      widget.onPositionsChanged?.call(_positions);
    } else {
      setState(() => _position = next);
      widget.onChanged(next);
    }
  }

  void _reset() {
    if (widget.category == 'coffrets') {
      _emit(const LogoPosition());
    } else {
      _emit(const LogoPosition());
    }
  }

  void _setProductColor(String id, Color color) {
    setState(() {
      _productColors = {
        ..._productColors,
        id: color,
      };
    });
    widget.onProductColorsChanged?.call(_productColors);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartFocalPoint = details.focalPoint;
    _positionAtGestureStart = widget.category == 'coffrets'
        ? (_positions[_coffretSubCategory] ?? const LogoPosition())
        : _position;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final metrics = _metrics;
    final startPoint = _gestureStartFocalPoint;
    final startPosition = _positionAtGestureStart;
    if (metrics == null || startPoint == null || startPosition == null) {
      return;
    }

    final dx = details.focalPoint.dx - startPoint.dx;
    final dy = details.focalPoint.dy - startPoint.dy;

    var next = startPosition.copyWith(
      x: startPosition.x + (dx / metrics.printArea.width),
      y: startPosition.y + (dy / metrics.printArea.height),
    );

    if (details.pointerCount > 1) {
      next = next.copyWith(
        scale: (startPosition.scale * details.scale).clamp(0.12, 0.9),
        rotation: _normalizeRotation(startPosition.rotation + details.rotation),
      );
    }

    _emit(_clampToPrintArea(next, metrics));
  }

  LogoPosition _clampToPrintArea(
      LogoPosition position, _PreviewMetrics metrics) {
    final logoRect = _logoRectForScale(
      position.scale,
      metrics.printArea.size,
      _logoAspectRatio,
    );
    final rotatedSize = _rotatedBoundingSize(logoRect, position.rotation);
    final halfWidth = rotatedSize.width / 2;
    final halfHeight = rotatedSize.height / 2;
    final minX = halfWidth / metrics.printArea.width;
    final minY = halfHeight / metrics.printArea.height;

    return position.copyWith(
      x: position.x.clamp(minX, 1 - minX),
      y: position.y.clamp(minY, 1 - minY),
      scale: position.scale.clamp(0.12, 0.9),
      rotation: _normalizeRotation(position.rotation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCategory = widget.category == 'coffrets'
        ? 'coffret_$_coffretSubCategory'
        : widget.category;
    final config = _previewConfigs[effectiveCategory] ??
        _previewConfigFor(widget.category);

    final currentPos = widget.category == 'coffrets'
        ? (_positions[_coffretSubCategory] ?? const LogoPosition())
        : _position;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _buildMetrics(constraints.maxWidth, config);
        _metrics = metrics;
        final safePosition = _clampToPrintArea(currentPos, metrics);

        if (safePosition.x != currentPos.x ||
            safePosition.y != currentPos.y ||
            safePosition.scale != currentPos.scale ||
            safePosition.rotation != currentPos.rotation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _emit(safePosition);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Positionnement du logo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyBlue,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Le logo est limité a la zone imprimable visible ci-dessous.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reinitialiser'),
                ),
              ],
            ),
            if (widget.category == 'coffrets') ...[
              const SizedBox(height: 16),
              _CoffretSubCategorySelector(
                selected: _coffretSubCategory,
                onChanged: (val) => setState(() => _coffretSubCategory = val),
              ),
            ],
            const SizedBox(height: 12),
            _HintBanner(config: config),
            if (config.colorLayers.any((layer) => layer.canTint)) ...[
              const SizedBox(height: 12),
              _ProductColorControls(
                config: config,
                selectedColors: _productColors,
                onChanged: _setProductColor,
              ),
            ],
            const SizedBox(height: 12),
            GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Container(
                height: metrics.canvas.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BackdropPainter(
                          printArea: metrics.printArea,
                        ),
                      ),
                    ),
                    Positioned(
                      left: metrics.productRect.left,
                      top: metrics.productRect.top,
                      child: _ProductMockup(
                        config: config,
                        category: widget.category,
                        size: metrics.productRect.size,
                        selectedColors: _productColors,
                        selectedMaterial: widget.selectedMaterial,
                      ),
                    ),
                    Positioned(
                      left: metrics.printArea.left,
                      top: metrics.printArea.top,
                      child: _PrintableAreaOverlay(
                        size: metrics.printArea.size,
                        label: config.printLabel,
                      ),
                    ),
                    Positioned(
                      left: metrics.printArea.left,
                      top: metrics.printArea.top,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: metrics.printArea.width,
                          height: metrics.printArea.height,
                          child: _LogoLayer(
                            logoFile: widget.logoFile,
                            position: safePosition,
                            printAreaSize: metrics.printArea.size,
                            logoAspectRatio: _logoAspectRatio,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              icon: Icons.photo_size_select_small_outlined,
              label: 'Taille',
              value: safePosition.scale,
              min: 0.12,
              max: 0.9,
              valueLabel: '${(safePosition.scale * 100).round()}%',
              onChanged: (value) {
                final metrics = _metrics;
                if (metrics == null) return;
                _emit(_clampToPrintArea(
                  safePosition.copyWith(scale: value),
                  metrics,
                ));
              },
            ),
            const SizedBox(height: 8),
            _SliderRow(
              icon: Icons.rotate_right_outlined,
              label: 'Rotation',
              value: safePosition.rotation,
              min: -math.pi,
              max: math.pi,
              valueLabel:
                  '${(safePosition.rotation * 180 / math.pi).round()} deg',
              onChanged: (value) {
                final metrics = _metrics;
                if (metrics == null) return;
                _emit(_clampToPrintArea(
                  safePosition.copyWith(rotation: value),
                  metrics,
                ));
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricBadge('X ${(safePosition.x * 100).round()}%'),
                _MetricBadge('Y ${(safePosition.y * 100).round()}%'),
                _MetricBadge('Zone ${config.printLabel}'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PreviewMetrics {
  final Size canvas;
  final Rect productRect;
  final Rect printArea;

  const _PreviewMetrics({
    required this.canvas,
    required this.productRect,
    required this.printArea,
  });
}

class _PreviewConfig {
  final String label;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final List<Color> colors;
  final Rect printArea;
  final String printLabel;
  final String? assetPath;
  final List<_ProductColorLayer> colorLayers;

  const _PreviewConfig({
    required this.label,
    required this.aspectRatio,
    required this.borderRadius,
    required this.colors,
    required this.printArea,
    required this.printLabel,
    this.assetPath,
    this.colorLayers = const [],
  });
}

class _ProductColorLayer {
  final String id;
  final String label;
  final String assetPath;
  final bool canTint;

  const _ProductColorLayer({
    required this.id,
    required this.label,
    required this.assetPath,
    this.canTint = true,
  });
}

const Map<String, _PreviewConfig> _previewConfigs = {
  'carnet': _PreviewConfig(
    label: 'Cahier',
    aspectRatio: 944 / 1124,
    borderRadius: BorderRadius.all(Radius.circular(14)),
    colors: [Color(0xFF1A237E), Color(0xFF3240A8)],
    printArea: Rect.fromLTWH(0.2, 0.07, 0.68, 0.84),
    printLabel: 'couverture',
    assetPath: 'assets/images/notebook canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'notebook',
        label: 'Cahier',
        assetPath: 'assets/images/notebook_color_mask.png',
      ),
      _ProductColorLayer(
        id: 'notebook-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/notebook shade + highlight.png',
        canTint: false,
      ),
      _ProductColorLayer(
        id: 'notebook-binding-coil',
        label: 'Spirale',
        assetPath: 'assets/images/binding coil.png',
        canTint: false,
      ),
    ],
  ),
  'gourdes_mug': _PreviewConfig(
    label: 'Mug',
    aspectRatio: 816 / 726,
    borderRadius: BorderRadius.all(Radius.circular(24)),
    colors: [Color(0xFFF7F8FB), Color(0xFFE5EAF6)],
    printArea: Rect.fromLTWH(0.16, 0.12, 0.54, 0.74),
    printLabel: 'face',
    assetPath: 'assets/images/cup canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'cup',
        label: 'Mug',
        assetPath: 'assets/images/cup_canvas-removebg-preview.png',
      ),
      _ProductColorLayer(
        id: 'cup-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/cup highlight shade.png',
        canTint: false,
      ),
    ],
  ),
  'porte_cles': _PreviewConfig(
    label: 'Porte-cles',
    aspectRatio: 1536 / 1024,
    borderRadius: BorderRadius.all(Radius.circular(18)),
    colors: [Color(0xFF8A97A8), Color(0xFFB4BFCC)],
    printArea: Rect.fromLTWH(0.07, 0.27, 0.51, 0.5),
    printLabel: 'centre',
    assetPath: 'assets/images/key chain canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'keychain',
        label: 'Porte-cles',
        assetPath: 'assets/images/keychain color.png',
      ),
      _ProductColorLayer(
        id: 'keychain-static',
        label: 'Chaine',
        assetPath: 'assets/images/key chain no color.png',
        canTint: false,
      ),
      _ProductColorLayer(
        id: 'keychain-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/keychain shade+highlight.png',
        canTint: false,
      ),
    ],
  ),
  'stylos': _PreviewConfig(
    label: 'Stylo',
    aspectRatio: 1129 / 675,
    borderRadius: BorderRadius.all(Radius.circular(999)),
    colors: [Color(0xFF1D1F24), Color(0xFF565C67)],
    printArea: Rect.fromLTWH(0.39, 0.24, 0.35, 0.42),
    printLabel: 'corps',
    assetPath: 'assets/images/pen canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'pen',
        label: 'Stylo',
        assetPath: 'assets/images/pen_canvas-removebg-preview.png',
      ),
      _ProductColorLayer(
        id: 'pen-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/pen shade + highlight.png',
        canTint: false,
      ),
    ],
  ),
  'sacs': _PreviewConfig(
    label: 'Sac',
    aspectRatio: 804 / 823,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    colors: [Color(0xFFC9B39C), Color(0xFFA78568)],
    printArea: Rect.fromLTWH(0.16, 0.18, 0.66, 0.68),
    printLabel: 'face',
    assetPath: 'assets/images/bag canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'bag',
        label: 'Sac',
        assetPath: 'assets/images/bag_canvas-removebg-preview.png',
      ),
      _ProductColorLayer(
        id: 'bag-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/tote bag shade + highlight.png',
        canTint: false,
      ),
    ],
  ),
  'coffret_notebook': _PreviewConfig(
    label: 'Cahier (Coffret)',
    aspectRatio: 944 / 1124,
    borderRadius: BorderRadius.all(Radius.circular(14)),
    colors: [Color(0xFF1A237E), Color(0xFF3240A8)],
    printArea: Rect.fromLTWH(0.2, 0.07, 0.68, 0.84),
    printLabel: 'couverture',
    assetPath: 'assets/images/notebook canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'coffret-notebook',
        label: 'Cahier',
        assetPath: 'assets/images/notebook_color_mask.png',
      ),
      _ProductColorLayer(
        id: 'coffret-notebook-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/notebook shade + highlight.png',
        canTint: false,
      ),
      _ProductColorLayer(
        id: 'coffret-notebook-binding-coil',
        label: 'Spirale',
        assetPath: 'assets/images/binding coil.png',
        canTint: false,
      ),
    ],
  ),
  'coffret_pen': _PreviewConfig(
    label: 'Stylo (Coffret)',
    aspectRatio: 1129 / 675,
    borderRadius: BorderRadius.all(Radius.circular(999)),
    colors: [Color(0xFF1D1F24), Color(0xFF565C67)],
    printArea: Rect.fromLTWH(0.39, 0.24, 0.35, 0.42),
    printLabel: 'corps',
    assetPath: 'assets/images/pen canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'coffret-pen',
        label: 'Stylo',
        assetPath: 'assets/images/pen_canvas-removebg-preview.png',
      ),
      _ProductColorLayer(
        id: 'coffret-pen-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/pen shade + highlight.png',
        canTint: false,
      ),
    ],
  ),
  'coffret_keychain': _PreviewConfig(
    label: 'Porte-clés (Coffret)',
    aspectRatio: 1536 / 1024,
    borderRadius: BorderRadius.all(Radius.circular(18)),
    colors: [Color(0xFF8A97A8), Color(0xFFB4BFCC)],
    printArea: Rect.fromLTWH(0.07, 0.27, 0.51, 0.5),
    printLabel: 'centre',
    assetPath: 'assets/images/key chain canvas.png',
    colorLayers: [
      _ProductColorLayer(
        id: 'coffret-keychain',
        label: 'Porte-clés',
        assetPath: 'assets/images/keychain color.png',
      ),
      _ProductColorLayer(
        id: 'coffret-keychain-static',
        label: 'Chaîne',
        assetPath: 'assets/images/key chain no color.png',
        canTint: false,
      ),
      _ProductColorLayer(
        id: 'coffret-keychain-shade-highlight',
        label: 'Relief',
        assetPath: 'assets/images/keychain shade+highlight.png',
        canTint: false,
      ),
    ],
  ),
};

_PreviewConfig _previewConfigFor(String category) {
  return _previewConfigs[category] ??
      const _PreviewConfig(
        label: 'Produit',
        aspectRatio: 1.0,
        borderRadius: BorderRadius.all(Radius.circular(18)),
        colors: [Color(0xFF1A237E), Color(0xFF4053C7)],
        printArea: Rect.fromLTWH(0.18, 0.18, 0.64, 0.64),
        printLabel: 'zone',
      );
}

_PreviewMetrics _buildMetrics(double width, _PreviewConfig config) {
  final canvasWidth = width;
  final productWidth = width * 0.68;
  final productHeight = productWidth / config.aspectRatio;
  final canvasHeight = math.max(productHeight + 72, 260).toDouble();
  final left = (canvasWidth - productWidth) / 2;
  final top = (canvasHeight - productHeight) / 2;
  final productRect = Rect.fromLTWH(left, top, productWidth, productHeight);
  final printRect = Rect.fromLTWH(
    productRect.left + (productRect.width * config.printArea.left),
    productRect.top + (productRect.height * config.printArea.top),
    productRect.width * config.printArea.width,
    productRect.height * config.printArea.height,
  );

  return _PreviewMetrics(
    canvas: Size(canvasWidth, canvasHeight),
    productRect: productRect,
    printArea: printRect,
  );
}

class _ProductMockup extends StatelessWidget {
  final _PreviewConfig config;
  final String category;
  final Size size;
  final Map<String, Color> selectedColors;
  final String? selectedMaterial;

  const _ProductMockup({
    required this.config,
    required this.category,
    required this.size,
    required this.selectedColors,
    this.selectedMaterial,
  });

  @override
  Widget build(BuildContext context) {
    if (config.assetPath != null) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: config.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: config.borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (config.colorLayers.isEmpty || config.label == 'Coffret')
                Image.asset(
                  config.assetPath!,
                  fit: BoxFit.cover,
                ),
              for (final layer in config.colorLayers)
                Positioned.fill(
                  child: _ProductLayerImage(
                    layer: layer,
                    category: category,
                    color: _resolveColorForLayer(layer.id, selectedColors),
                    selectedMaterial: selectedMaterial,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: config.borderRadius,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: config.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  config.label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.34),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductLayerImage extends StatelessWidget {
  final _ProductColorLayer layer;
  final String category;
  final Color color;
  final String? selectedMaterial;

  const _ProductLayerImage({
    required this.layer,
    required this.category,
    required this.color,
    this.selectedMaterial,
  });

  @override
  Widget build(BuildContext context) {
    if (!layer.canTint) {
      return Image.asset(
        layer.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    final isNotebookLayer =
        layer.id == 'notebook' || layer.id == 'coffret-notebook';
    final isCahierCategory = category == 'carnet';

    final texturePath = (isNotebookLayer && isCahierCategory)
        ? _materialTextures[selectedMaterial]
        : null;

    if (texturePath != null) {
      return _MaskedTextureWidget(
        maskPath: layer.assetPath,
        texturePath: texturePath,
        tintColor: color,
      );
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image.asset(
        layer.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

const _materialTextures = {
  'Couverture Cartonnée': 'assets/images/notebook cover carton (Couverture Cartonnée).png',
  'Carton Rigide': 'assets/images/notebook cover carton rigid.png',
  'Couverture Tissu': 'assets/images/notebook cover cloth (Couverture tissu).png',
  'Simili Cuir': 'assets/images/notebook cover cuir (Simili cuir).jpg',
};

class _MaskedTextureWidget extends StatefulWidget {
  final String maskPath;
  final String texturePath;
  final Color tintColor;

  const _MaskedTextureWidget({
    required this.maskPath,
    required this.texturePath,
    required this.tintColor,
  });

  @override
  State<_MaskedTextureWidget> createState() => _MaskedTextureWidgetState();
}

class _MaskedTextureWidgetState extends State<_MaskedTextureWidget> {
  ui.Image? _maskImage;
  ui.Image? _textureImage;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(covariant _MaskedTextureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maskPath != widget.maskPath ||
        oldWidget.texturePath != widget.texturePath) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    final maskData = await rootBundle.load(widget.maskPath);
    final textureData = await rootBundle.load(widget.texturePath);

    final maskCodec =
        await ui.instantiateImageCodec(maskData.buffer.asUint8List());
    final textureCodec =
        await ui.instantiateImageCodec(textureData.buffer.asUint8List());

    final maskFrame = await maskCodec.getNextFrame();
    final textureFrame = await textureCodec.getNextFrame();

    if (mounted) {
      setState(() {
        _maskImage = maskFrame.image;
        _textureImage = textureFrame.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_maskImage == null || _textureImage == null) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      painter: _MaskedTexturePainter(
        maskImage: _maskImage!,
        textureImage: _textureImage!,
        tintColor: widget.tintColor,
      ),
    );
  }
}

class _MaskedTexturePainter extends CustomPainter {
  final ui.Image maskImage;
  final ui.Image textureImage;
  final Color tintColor;

  _MaskedTexturePainter({
    required this.maskImage,
    required this.textureImage,
    required this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    // 1. Draw the mask
    paintImage(
      canvas: canvas,
      rect: rect,
      image: maskImage,
      fit: BoxFit.contain,
    );

    // 2. Composite the texture inside the mask
    final texturePaint = Paint()..blendMode = ui.BlendMode.srcIn;
    canvas.saveLayer(rect, texturePaint);
    paintImage(
      canvas: canvas,
      rect: rect,
      image: textureImage,
      fit: BoxFit.cover,
    );

    // 3. Apply color tint (if not white)
    if (tintColor != Colors.white) {
      final tintPaint = Paint()..blendMode = ui.BlendMode.modulate;
      canvas.drawRect(
        rect,
        tintPaint..color = tintColor,
      );
    }
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MaskedTexturePainter oldDelegate) {
    return oldDelegate.maskImage != maskImage ||
        oldDelegate.textureImage != textureImage ||
        oldDelegate.tintColor != tintColor;
  }
}

class _ProductColorControls extends StatelessWidget {
  final _PreviewConfig config;
  final Map<String, Color> selectedColors;
  final void Function(String id, Color color) onChanged;

  const _ProductColorControls({
    required this.config,
    required this.selectedColors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final layers = config.colorLayers.where((layer) => layer.canTint).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_outlined, size: 16, color: AppColors.navyBlue),
              SizedBox(width: 8),
              Text(
                'Couleur produit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < layers.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ColorPickerRow(
              label: layers[i].label,
              selectedColor: selectedColors[layers[i].id] ??
                  _defaultColorForLayer(layers[i].id),
              onChanged: (color) => onChanged(layers[i].id, color),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorPickerRow extends StatefulWidget {
  final String label;
  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  const _ColorPickerRow({
    required this.label,
    required this.selectedColor,
    required this.onChanged,
  });

  @override
  State<_ColorPickerRow> createState() => _ColorPickerRowState();
}

class _ColorPickerRowState extends State<_ColorPickerRow> {
  bool _showCustomPicker = false;
  Color? _customColor;

  @override
  void initState() {
    super.initState();
    _updateCustomColor();
  }

  @override
  void didUpdateWidget(covariant _ColorPickerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      _updateCustomColor();
    }
  }

  void _updateCustomColor() {
    if (!_productPalette.contains(widget.selectedColor)) {
      _customColor = widget.selectedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _hexFromColor(widget.selectedColor),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _productPalette)
                    _ColorSwatchButton(
                      color: color,
                      selected: color == widget.selectedColor,
                      onTap: () => widget.onChanged(color),
                    ),
                  if (_customColor != null)
                    _ColorSwatchButton(
                      color: _customColor!,
                      selected: widget.selectedColor == _customColor,
                      onTap: () => widget.onChanged(_customColor!),
                    ),
                  _CustomColorButton(
                    expanded: _showCustomPicker,
                    onTap: () => setState(() {
                      _showCustomPicker = !_showCustomPicker;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InwinColorPicker(
              onColorChanged: (color) {
                setState(() => _customColor = color);
                widget.onChanged(color);
              },
              initialColor: widget.selectedColor,
            ),
          ),
          crossFadeState: _showCustomPicker
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}

class _CustomColorButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _CustomColorButton({
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Couleur personnalisee',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: expanded ? AppColors.navyBlue : Colors.white,
            border: Border.all(
              color: expanded ? AppColors.navyBlue : AppColors.divider,
              width: expanded ? 2 : 1,
            ),
          ),
          child: Icon(
            expanded ? Icons.close : Icons.add,
            size: 18,
            color: expanded ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

String _hexFromColor(Color color) {
  final value = color.toARGB32() & 0x00FFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _ColorSwatchButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _colorLabel(color),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 30,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.navyBlue : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrintableAreaOverlay extends StatelessWidget {
  final Size size;
  final String label;

  const _PrintableAreaOverlay({
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: AppColors.lightGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.lightGold.withValues(alpha: 0.75),
            width: 1.2,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Zone $label',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.navyBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoLayer extends StatelessWidget {
  final File logoFile;
  final LogoPosition position;
  final Size printAreaSize;
  final double logoAspectRatio;

  const _LogoLayer({
    required this.logoFile,
    required this.position,
    required this.printAreaSize,
    required this.logoAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final logoRect = _logoRectForScale(
      position.scale,
      printAreaSize,
      logoAspectRatio,
    );
    final centerX = position.x * printAreaSize.width;
    final centerY = position.y * printAreaSize.height;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: centerX - 3,
          top: centerY - 3,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.lightGold,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: centerX - (logoRect.width / 2),
          top: centerY - (logoRect.height / 2),
          child: Transform.rotate(
            angle: position.rotation,
            child: Container(
              width: logoRect.width,
              height: logoRect.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        child: Image.file(
                          logoFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DashedBorderPainter(),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.navyBlue,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        size: 8,
                        color: AppColors.navyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final Rect printArea;

  const _BackdropPainter({
    required this.printArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navyBlue.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paint);

    final linePaint = Paint()
      ..color = AppColors.navyBlue.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(printArea.center.dx, 0),
      Offset(printArea.center.dx, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, printArea.center.dy),
      Offset(size.width, printArea.center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) {
    return oldDelegate.printArea != printArea;
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashGap = 4.0;

    void drawDashedLine(Offset start, Offset end) {
      final totalLength = (end - start).distance;
      double drawn = 0;
      while (drawn < totalLength) {
        final segmentStart = Offset.lerp(start, end, drawn / totalLength)!;
        final segmentEnd = Offset.lerp(
          start,
          end,
          math.min((drawn + dashWidth) / totalLength, 1.0).toDouble(),
        )!;
        canvas.drawLine(segmentStart, segmentEnd, paint);
        drawn += dashWidth + dashGap;
      }
    }

    drawDashedLine(Offset.zero, Offset(size.width, 0));
    drawDashedLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawDashedLine(Offset(size.width, size.height), Offset(0, size.height));
    drawDashedLine(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HintBanner extends StatelessWidget {
  final _PreviewConfig config;

  const _HintBanner({
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(
              child: _Hint(
                  icon: Icons.pan_tool_outlined, text: '1 doigt  Deplacer')),
          Expanded(
              child:
                  _Hint(icon: Icons.pinch_outlined, text: '2 doigts  Taille')),
          Expanded(
              child: _Hint(
                  icon: Icons.rotate_right_outlined,
                  text: '2 doigts  Rotation')),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.navyBlue),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.navyBlue),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.navyBlue,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.navyBlue,
              overlayColor: AppColors.navyBlue.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 54,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.navyBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String text;

  const _MetricBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navyBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.navyBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

double _normalizeRotation(double angle) {
  while (angle > math.pi) {
    angle -= math.pi * 2;
  }
  while (angle < -math.pi) {
    angle += math.pi * 2;
  }
  return angle;
}

Size _logoRectForScale(double scale, Size printAreaSize, double aspectRatio) {
  final safeAspectRatio = aspectRatio <= 0 ? 1.0 : aspectRatio;
  final maxWidth = printAreaSize.width * scale;

  if (safeAspectRatio >= 1) {
    return Size(maxWidth, maxWidth / safeAspectRatio);
  }

  return Size(maxWidth * safeAspectRatio, maxWidth);
}

Size _rotatedBoundingSize(Size size, double rotation) {
  final cosTheta = math.cos(rotation).abs();
  final sinTheta = math.sin(rotation).abs();

  return Size(
    (size.width * cosTheta) + (size.height * sinTheta),
    (size.width * sinTheta) + (size.height * cosTheta),
  );
}

const List<Color> _productPalette = [
  Color(0xFF111827),
  Color(0xFFFFFFFF),
  Color(0xFF1A237E),
  Color(0xFF2563EB),
  Color(0xFF16A34A),
  Color(0xFFDC2626),
  Color(0xFFF59E0B),
  Color(0xFFC9B39C),
  Color(0xFF8A97A8),
];

Map<String, Color> _defaultProductColorsFor(String category) {
  final config = _previewConfigFor(category);
  return {
    for (final layer in config.colorLayers.where((layer) => layer.canTint))
      layer.id: _defaultColorForLayer(layer.id),
  };
}

Color _defaultColorForLayer(String id) {
  switch (id) {
    case 'cup':
      return const Color(0xFFFFFFFF);
    case 'bag':
      return const Color(0xFFC9B39C);
    case 'keychain':
    case 'coffret-keychain':
      return const Color(0xFF8A97A8);
    case 'pen':
    case 'coffret-pen':
      return const Color(0xFF111827);
    case 'notebook':
    case 'coffret-notebook':
    default:
      return const Color(0xFF1A237E);
  }
}

Color _resolveColorForLayer(String id, Map<String, Color> selectedColors) {
  if (id.endsWith('-shade-highlight')) {
    final baseId = id.replaceAll('-shade-highlight', '');
    return selectedColors[baseId] ?? _defaultColorForLayer(baseId);
  }
  if (id.endsWith('-static')) {
    final baseId = id.replaceAll('-static', '');
    return selectedColors[baseId] ?? _defaultColorForLayer(baseId);
  }
  return selectedColors[id] ?? _defaultColorForLayer(id);
}

String _colorLabel(Color color) {
  if (color == const Color(0xFF111827)) return 'Noir';
  if (color == const Color(0xFFFFFFFF)) return 'Blanc';
  if (color == const Color(0xFF1A237E)) return 'Bleu marine';
  if (color == const Color(0xFF2563EB)) return 'Bleu';
  if (color == const Color(0xFF16A34A)) return 'Vert';
  if (color == const Color(0xFFDC2626)) return 'Rouge';
  if (color == const Color(0xFFF59E0B)) return 'Orange';
  if (color == const Color(0xFFC9B39C)) return 'Beige';
  if (color == const Color(0xFF8A97A8)) return 'Gris';
  return 'Couleur';
}

class _CoffretSubCategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CoffretSubCategorySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildItem('notebook', 'Cahier', Icons.book_outlined),
          _buildItem('pen', 'Stylo', Icons.edit_outlined),
          _buildItem('keychain', 'Porte-clés', Icons.key_outlined),
        ],
      ),
    );
  }

  Widget _buildItem(String value, String label, IconData icon) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navyBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
