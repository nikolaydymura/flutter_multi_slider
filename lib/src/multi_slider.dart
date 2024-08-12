part of '../flutter_multi_slider.dart';

class MultiSlider extends StatefulWidget {
  const MultiSlider({
    required this.values,
    required this.onChanged,
    this.max = 1,
    this.min = 0,
    this.onChangeStart,
    this.onChangeEnd,
    this.color,
    this.rangeColors,
    this.thumbColor,
    this.thumbInactiveColor = Colors.grey,
    this.thumbRadius = 10,
    this.horizontalPadding = 26.0,
    this.height = 45,
    this.activeTrackSize = 6,
    this.inactiveTrackSize = 4,
    this.indicator,
    this.selectedIndicator = defaultIndicator,
    this.divisions,
    this.thumbBuilder = defaultThumbBuilder,
    this.trackbarBuilder = defaultTrackbarBuilder,
    this.textDirection = TextDirection.ltr,
    this.textHeightOffset = 30,
    this.direction = Axis.horizontal,
    Key? key,
  })  : range = max - min,
        assert(values.length != 0),
        assert(divisions == null || divisions > 0),
        assert(max - min >= 0),
        super(key: key);

  /// [MultiSlider] maximum value.
  final double max;

  /// [MultiSlider] minimum value.
  final double min;

  /// Difference between [max] and [min]. Must be positive!
  final double range;

  /// [MultiSlider] vertical dimension. Used by [GestureDetector] and [CustomPainter].
  final double height;

  /// Empty space between the [MultiSlider] bar and the end of [GestureDetector] zone.
  final double horizontalPadding;

  /// Bar and indicators active color.
  final Color? color;

  /// Bar range colors from left to right. Your choice here will be displayed
  /// unconditionally! If you want more control, use [trackbarBuilder] instead!
  final List<Color>? rangeColors;

  /// Thumb radius.
  final double thumbRadius;

  /// Thumb color.
  final Color? thumbColor;

  /// Thumb inactive color.
  final Color? thumbInactiveColor;

  /// Default indicator builder. Used to draw values, even if user is not
  /// interacting with this component. This is null by default, so you have to
  /// use [defaultIndicator] or define your own if you want to display values.
  final IndicatorBuilder? indicator;

  /// Selected indicator builder. Used to draw only the selected value.
  /// [defaultIndicator] is used by default. You can define your own or
  /// set [null] to not draw anything. If [indicator] is set and
  /// [selectedIndicator] is null, then [indicator] will be used to
  /// draw selected value indicator.
  final IndicatorBuilder? selectedIndicator;

  /// Active track size.
  final double activeTrackSize;

  /// Inactive track size.
  final double inactiveTrackSize;

  /// List of ordered values which will be changed by user gestures with this widget.
  final List<double> values;

  /// Callback for every user slide gesture.
  final ValueChanged<List<double>>? onChanged;

  /// Callback for every time user click on this widget.
  final ValueChanged<List<double>>? onChangeStart;

  /// Callback for every time user stop click/slide on this widget.
  final ValueChanged<List<double>>? onChangeEnd;

  /// Number of divisions for discrete Slider.
  final int? divisions;

  /// Used to setup ranges draw. For a simplified use, try [rangeColors].
  /// Run from left to right for each [ValueRange]. Return [TrackbarOptions]
  /// where you setup if the current track is active or not. You can override
  /// its [size] or [Color] by passing a color different from null.
  ///
  /// You can use this builder with [rangeColors]. [rangeColors] has preference.
  final TrackbarBuilder trackbarBuilder;

  /// [TextDirection] used on [indicator] and [selectedIndicator] drawing.
  final TextDirection textDirection;

  /// Height offset used in [indicator] and [selectedIndicator].
  final double textHeightOffset;

  /// Use to set custom color, elevation and radius for each thumb indicator
  /// individually.
  final ThumbBuilder thumbBuilder;

  final Axis direction;

  static IndicatorOptions defaultIndicator(ThumbValue value) {
    return const IndicatorOptions();
  }

  static TrackbarOptions defaultTrackbarBuilder(ValueRange valueRange) {
    return TrackbarOptions(isActive: valueRange.isOdd);
  }

  static ThumbOptions defaultThumbBuilder(ThumbValue value) {
    return const ThumbOptions();
  }

  @override
  State<MultiSlider> createState() => _MultiSliderState();
}

class _MultiSliderState extends State<MultiSlider> {
  late double _maxLength;
  late ThemeData _theme;
  late SliderThemeData _sliderTheme;

  int? _selectedInputIndex;

  @override
  void didChangeDependencies() {
    _theme = Theme.of(context);
    _sliderTheme = SliderTheme.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onChanged == null || widget.range == 0;
    final indicatorTextTheme = _theme.textTheme.labelMedium;
    final selectedIndicatorTextTheme = _theme.textTheme.bodyLarge;

    IndicatorBuilder? indicator, selectedIndicator;
    if (widget.indicator != null) {
      indicator = selectedIndicator = (value) {
        final currentValue = widget.indicator!(value);
        return IndicatorOptions(
          draw: currentValue.draw,
          formatter: currentValue.formatter,
          style: indicatorTextTheme?.copyFromOther(currentValue.style),
          offsetShifter: currentValue.offsetShifter,
        );
      };
    }
    if (widget.selectedIndicator != null) {
      selectedIndicator = (value) {
        final currentValue = widget.selectedIndicator!(value);
        return IndicatorOptions(
          draw: currentValue.draw,
          formatter: currentValue.formatter,
          style: selectedIndicatorTextTheme?.copyFromOther(currentValue.style),
          offsetShifter: currentValue.offsetShifter
        );
      };
    }
    final enabledThumbColor = widget.thumbColor ?? //
        widget.color ??
        _sliderTheme.activeTrackColor ??
        _theme.colorScheme.primary;

    final disabledThumbColor = widget.thumbInactiveColor ?? //
        widget.thumbColor ??
        _sliderTheme.activeTrackColor ??
        Colors.grey;

    final thumbColor = isDisabled ? disabledThumbColor : enabledThumbColor;
    final enabledActiveTrackColor = widget.color ?? //
        _sliderTheme.activeTrackColor ??
        _theme.colorScheme.primary;

    final enabledInactiveTrackColor = widget.color?.withOpacity(0.24) ??
        _sliderTheme.inactiveTrackColor ??
        _theme.colorScheme.primary.withOpacity(0.24);

    final disabledActiveTrackColor = _sliderTheme.disabledActiveTrackColor ?? //
        _theme.colorScheme.onSurface.withOpacity(0.40);

    final disabledInactiveTrackColor = _sliderTheme.disabledInactiveTrackColor ?? //
        _theme.colorScheme.onSurface.withOpacity(0.12);

    final activeTrackColor = isDisabled //
        ? disabledActiveTrackColor
        : enabledActiveTrackColor;

    final inactiveTrackColor = isDisabled //
        ? disabledInactiveTrackColor
        : enabledInactiveTrackColor;

    TrackbarOptions trackbarBuilder(ValueRange v) {
      final currentValue = widget.trackbarBuilder.call(v);
      final isActive = currentValue.isActive;
      Color color = currentValue.color ?? //
          (isActive ? activeTrackColor : inactiveTrackColor);
      final size = currentValue.size ?? //
          (isActive ? widget.activeTrackSize : widget.inactiveTrackSize);

      if (widget.rangeColors != null && v.index < widget.rangeColors!.length) {
        color = widget.rangeColors![v.index];
      }

      return TrackbarOptions(
        isActive: isActive,
        color: color,
        size: size,
      );
    }

    ThumbOptions thumbBuilder(ThumbValue value) {
      final currentValue = widget.thumbBuilder(value);

      return ThumbOptions(
        color: currentValue.color ?? thumbColor,
        elevation: currentValue.elevation ?? (value.isSelected ? 3 : 0),
        radius: currentValue.radius ?? widget.thumbRadius,
        pathBuilder: currentValue.pathBuilder,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxLength = widget.direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
        return GestureDetector(
          onPanDown: isDisabled ? null : _onPanDown,
          onPanUpdate: isDisabled ? null : _handleOnChanged,
          onPanCancel: isDisabled ? null : _handleOnChangeEnd,
          onPanEnd: isDisabled ? null : (_) => _handleOnChangeEnd(),
          child: Container(
            constraints: constraints,
            width: double.infinity,
            height: widget.height,
            child: CustomPaint(
              painter: _MultiSliderPainter(
                trackbarBuilder: trackbarBuilder,
                divisions: widget.divisions,
                rangeColors: widget.rangeColors,
                selectedInputIndex: _selectedInputIndex,
                values: widget.values,
                indicator: indicator,
                selectedIndicator: selectedIndicator,
                horizontalPadding: widget.horizontalPadding,
                activeTrackSize: widget.activeTrackSize,
                inactiveTrackSize: widget.inactiveTrackSize,
                textDirection: widget.textDirection,
                textHeightOffset: widget.textHeightOffset,
                thumbBuilder: thumbBuilder,
                thumbColor: thumbColor,
                direction: widget.direction,
                positions: widget.values //
                    .map(_convertValueToPixelPosition)
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPanDown(DragDownDetails details) {
    double valuePosition = _convertPixelPositionToValue(
      widget.direction == Axis.horizontal ? details.localPosition.dx : _maxLength - details.localPosition.dy,
    );

    int index = findNearestValueIndex(valuePosition, widget.values);

    setState(() => _selectedInputIndex = index);

    final updatedValues = updateInternalValues(widget.direction == Axis.horizontal ? details.localPosition.dx : _maxLength - details.localPosition.dy);
    widget.onChanged!(updatedValues);
    widget.onChangeStart?.call(updatedValues);
  }

  void _handleOnChanged(DragUpdateDetails details) {
    widget.onChanged!(updateInternalValues(widget.direction == Axis.horizontal ? details.localPosition.dx : _maxLength - details.localPosition.dy));
  }

  void _handleOnChangeEnd() {
    setState(() => _selectedInputIndex = null);

    widget.onChangeEnd?.call(widget.values);
  }

  double _convertValueToPixelPosition(double value) {
    return (value - widget.min) * //
            (_maxLength - 2 * widget.horizontalPadding) /
            (widget.range) +
        widget.horizontalPadding;
  }

  double _convertPixelPositionToValue(double pixelPosition) {
    final value = (pixelPosition - widget.horizontalPadding) * //
            (widget.range) /
            (_maxLength - 2 * widget.horizontalPadding) +
        widget.min;

    return value;
  }

  List<double> updateInternalValues(double xPosition) {
    if (_selectedInputIndex == null) return widget.values;

    List<double> copiedValues = [...widget.values];

    double convertedPosition = _convertPixelPositionToValue(xPosition);

    copiedValues[_selectedInputIndex!] = convertedPosition.clamp(
      _calculateInnerBound(),
      _calculateOuterBound(),
    );

    if (widget.divisions != null) {
      return copiedValues
          .map<double>(
            (value) => _getDiscreteValue(
              value,
              widget.min,
              widget.max,
              widget.divisions!,
            ),
          )
          .toList();
    }
    return copiedValues;
  }

  double _calculateInnerBound() {
    return _selectedInputIndex == 0 //
        ? widget.min
        : widget.values[_selectedInputIndex! - 1];
  }

  double _calculateOuterBound() {
    return _selectedInputIndex == widget.values.length - 1 //
        ? widget.max
        : widget.values[_selectedInputIndex! + 1];
  }
}
