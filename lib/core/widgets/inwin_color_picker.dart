import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';

class InwinColorPicker extends StatefulWidget {
  final ValueChanged<Color> onColorChanged;
  final Color initialColor;

  const InwinColorPicker({
    super.key,
    required this.onColorChanged,
    this.initialColor = Colors.yellow,
  });

  @override
  State<InwinColorPicker> createState() => _InwinColorPickerState();
}

class _InwinColorPickerState extends State<InwinColorPicker> {
  late HSVColor _hsvColor;
  late TextEditingController _hexCtrl;
  late FocusNode _hexFocusNode;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexCtrl = TextEditingController(text: _hexFromColor(widget.initialColor));
    _hexFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant InwinColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor &&
        !_hexFocusNode.hasFocus) {
      _setColor(widget.initialColor, notify: false);
    }
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _hexFocusNode.dispose();
    super.dispose();
  }

  void _setColor(Color color, {bool notify = true}) {
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
      _hexCtrl.text = _hexFromColor(color);
    });
    if (notify) widget.onColorChanged(color);
  }

  void _setHsv(HSVColor color) {
    setState(() {
      _hsvColor = color;
      _hexCtrl.text = _hexFromColor(color.toColor());
    });
    widget.onColorChanged(color.toColor());
  }

  void _applyHex(String value) {
    final parsed = _colorFromHex(value);
    if (parsed == null) return;
    _setColor(parsed);
  }

  static String _hexFromColor(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color? _colorFromHex(String input) {
    final normalized = input.replaceAll('#', '').trim();
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  void _updateSaturationValue(Offset localPosition, Size size) {
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    _setHsv(_hsvColor.withSaturation(saturation).withValue(value));
  }

  void _updateHue(Offset localPosition, double width) {
    final hue = (localPosition.dx / width).clamp(0.0, 1.0) * 360;
    _setHsv(_hsvColor.withHue(hue));
  }

  Widget _buildSaturationValuePicker() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 128);
        return GestureDetector(
          onPanDown: (details) => _updateSaturationValue(
            details.localPosition,
            size,
          ),
          onPanUpdate: (details) => _updateSaturationValue(
            details.localPosition,
            size,
          ),
          child: CustomPaint(
            painter: _SaturationValuePainter(
                _hsvColor.withSaturation(1).withValue(1).toColor()),
            child: SizedBox(
              height: size.height,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned(
                    left: (_hsvColor.saturation * size.width)
                            .clamp(0.0, size.width) -
                        8,
                    top: ((1 - _hsvColor.value) * size.height)
                            .clamp(0.0, size.height) -
                        8,
                    child: _PickerThumb(color: _hsvColor.toColor()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHueSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (details) => _updateHue(details.localPosition, width),
          onPanUpdate: (details) => _updateHue(details.localPosition, width),
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: ((_hsvColor.hue / 360) * width).clamp(0.0, width) - 8,
                  top: 6,
                  child: _PickerThumb(
                      color:
                          _hsvColor.withSaturation(1).withValue(1).toColor()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
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
            ),
            child: Slider(
              min: 0,
              max: 1,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHexField() {
    return TextField(
      controller: _hexCtrl,
      focusNode: _hexFocusNode,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
        LengthLimitingTextInputFormatter(7),
      ],
      decoration: InputDecoration(
        isDense: true,
        labelText: 'HEX',
        prefixIcon: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hsvColor.toColor(),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.navyBlue),
        ),
      ),
      onChanged: _applyHex,
      onSubmitted: _applyHex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSaturationValuePicker(),
        const SizedBox(height: 12),
        _buildHueSlider(),
        const SizedBox(height: 8),
        _buildValueSlider(
          label: 'Saturation',
          value: _hsvColor.saturation,
          onChanged: (value) => _setHsv(_hsvColor.withSaturation(value)),
        ),
        _buildValueSlider(
          label: 'Brillance',
          value: _hsvColor.value,
          onChanged: (value) => _setHsv(_hsvColor.withValue(value)),
        ),
        const SizedBox(height: 8),
        _buildHexField(),
      ],
    );
  }
}

class _PickerThumb extends StatelessWidget {
  final Color color;

  const _PickerThumb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  final Color hueColor;

  const _SaturationValuePainter(this.hueColor);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, hueColor],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      basePaint,
    );

    final valuePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      valuePaint,
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.divider;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hueColor != hueColor;
  }
}
