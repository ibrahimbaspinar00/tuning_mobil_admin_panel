import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool allowHalfRating;
  final bool readOnly;
  final Function(double)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.allowHalfRating = false,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        final isActive = starIndex <= rating;
        final isHalfActive = allowHalfRating && 
            starIndex - 0.5 <= rating && 
            starIndex > rating;

        return GestureDetector(
          onTap: readOnly ? null : () {
            if (onRatingChanged != null) {
              onRatingChanged!(starIndex.toDouble());
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Icon(
              isActive
                  ? Icons.star
                  : isHalfActive
                      ? Icons.star_half
                      : Icons.star_border,
              color: isActive || isHalfActive ? activeColor : inactiveColor,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRatingText;
  final TextStyle? textStyle;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showRatingText = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(
          rating: rating,
          maxRating: maxRating,
          size: size,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          readOnly: true,
        ),
        if (showRatingText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: textStyle ?? TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ],
    );
  }
}

class StarRatingInput extends StatefulWidget {
  final double initialRating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Function(double)? onRatingChanged;
  final String? label;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 24.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.onRatingChanged,
    this.label,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        StarRating(
          rating: _currentRating,
          maxRating: widget.maxRating,
          size: widget.size,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          onRatingChanged: (rating) {
            setState(() {
              _currentRating = rating;
            });
            widget.onRatingChanged?.call(rating);
          },
        ),
        const SizedBox(height: 4),
        Text(
          _getRatingText(_currentRating),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'Değerlendirme seçin';
    if (rating <= 1) return 'Çok kötü';
    if (rating <= 2) return 'Kötü';
    if (rating <= 3) return 'Orta';
    if (rating <= 4) return 'İyi';
    return 'Çok iyi';
  }
}
