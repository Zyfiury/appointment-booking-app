import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/service_service.dart';
import '../services/availability_service.dart';
import '../services/provider_image_service.dart';
import '../widgets/fade_in_widget.dart';
import '../widgets/layered_card.dart';

class ProviderOnboardingChecklist extends StatefulWidget {
  const ProviderOnboardingChecklist({super.key});

  @override
  State<ProviderOnboardingChecklist> createState() => _ProviderOnboardingChecklistState();
}

class _ProviderOnboardingChecklistState extends State<ProviderOnboardingChecklist> {
  final ServiceService _serviceService = ServiceService();
  final AvailabilityService _availabilityService = AvailabilityService();
  final ProviderImageService _imageService = ProviderImageService();
  
  bool _loading = true;
  int _completedSteps = 0;
  final int _totalSteps = 4;
  
  bool _hasLocation = false;
  bool _hasServices = false;
  bool _hasAvailability = false;
  bool _hasPhotos = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    setState(() {
      _loading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final providerId = authProvider.user?.id;
      
      if (providerId == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      // Check location
      final user = authProvider.user;
      _hasLocation = user?.latitude != null && user?.longitude != null;

      // Check services
      final services = await _serviceService.getServices(providerId: providerId);
      _hasServices = services.isNotEmpty;

      // Check availability
      try {
        final availability = await _availabilityService.getMyAvailability();
        _hasAvailability = availability.isNotEmpty;
      } catch (e) {
        _hasAvailability = false;
      }

      // Check photos
      try {
        final images = await _imageService.getMyImages();
        _hasPhotos = images.isNotEmpty;
      } catch (e) {
        _hasPhotos = false;
      }

      _completedSteps = [
        _hasLocation,
        _hasServices,
        _hasAvailability,
        _hasPhotos,
      ].where((completed) => completed).length;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  double get _completionPercentage => _totalSteps > 0 ? (_completedSteps / _totalSteps) : 0.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    // Don't show if onboarding is complete
    if (!_loading && _completedSteps == _totalSteps) {
      return const SizedBox.shrink();
    }

    return FadeInWidget(
      child: FloatingCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.checklist,
                    color: colors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_completedSteps of $_totalSteps steps completed',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _completionPercentage,
                backgroundColor: colors.surfaceColor,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primaryColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            // Checklist items
            _buildChecklistItem(
              'Set Location',
              _hasLocation,
              Icons.location_on,
              () {
                Navigator.pushNamed(context, '/provider/location');
              },
              colors,
            ),
            _buildChecklistItem(
              'Add Services',
              _hasServices,
              Icons.work_outline,
              () {
                Navigator.pushNamed(context, '/provider/services');
              },
              colors,
            ),
            _buildChecklistItem(
              'Set Availability',
              _hasAvailability,
              Icons.calendar_today,
              () {
                Navigator.pushNamed(context, '/provider/availability');
              },
              colors,
            ),
            _buildChecklistItem(
              'Add Photos (Optional)',
              _hasPhotos,
              Icons.photo_library,
              () {
                // Navigate to gallery screen
                // Navigator.pushNamed(context, '/provider/gallery');
              },
              colors,
              optional: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
    String title,
    bool completed,
    IconData icon,
    VoidCallback onTap,
    ThemeColors colors, {
    bool optional = false,
  }) {
    return InkWell(
      onTap: completed ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: completed
                    ? colors.primaryColor.withOpacity(0.15)
                    : colors.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check_circle : icon,
                color: completed ? colors.primaryColor : colors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
                  color: completed ? colors.textPrimary : colors.textSecondary,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (optional)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '(Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (!completed)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
