import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final bool showNumber;
  final bool showCount;

  const RatingWidget({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.size = 16,
    this.showNumber = true,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(
              Icons.star,
              color: colors.warningColor,
              size: size,
            );
          } else if (index < rating) {
            return Icon(
              Icons.star_half,
              color: colors.warningColor,
              size: size,
            );
          } else {
            return Icon(
              Icons.star_border,
              color: colors.textSecondary,
              size: size,
            );
          }
        }),
        if (showNumber) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.9,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
        if (showCount && totalRatings > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingSelector extends StatefulWidget {
  final Function(int) onRatingChanged;
  final int initialRating;

  const RatingSelector({
    super.key,
    required this.onRatingChanged,
    this.initialRating = 0,
  });

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  late int _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final rating = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = rating;
            });
            widget.onRatingChanged(rating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              rating <= _selectedRating
                  ? Icons.star
                  : Icons.star_border,
              color: rating <= _selectedRating
                  ? colors.warningColor
                  : colors.textSecondary,
              size: 40,
            ),
          ),
        );
      }),
    );
  }
}
