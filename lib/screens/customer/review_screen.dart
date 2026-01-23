import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/rating_widget.dart';
import 'my_appointments_screen.dart';
import '../../providers/theme_provider.dart';


class ReviewScreen extends StatefulWidget {
  final Appointment appointment;

  const ReviewScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please write a review';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _reviewService.createReview(
        appointmentId: widget.appointment.id,
        providerId: widget.appointment.provider.id,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: colors.accentColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Failed to submit review. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Write Review'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Appointment Info
              FadeInWidget(
                child: FloatingCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appointment.service.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provider: ${widget.appointment.provider.name}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Rating Selection
              FadeInWidget(
                duration: const Duration(milliseconds: 200),
                child: FloatingCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'How was your experience?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      RatingSelector(
                        initialRating: _selectedRating,
                        onRatingChanged: (rating) {
                          setState(() {
                            _selectedRating = rating;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Review Comment
              FadeInWidget(
                duration: const Duration(milliseconds: 300),
                child: FloatingCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Write your review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        maxLines: 6,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                          filled: true,
                          fillColor: colors.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: colors.errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button
              FadeInWidget(
                duration: const Duration(milliseconds: 400),
                child: AnimatedButton(
                  text: 'Submit Review',
                  icon: Icons.send,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submitReview,
                  backgroundColor: colors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
