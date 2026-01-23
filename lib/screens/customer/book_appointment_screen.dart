import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/provider.dart' as provider_model;
import 'package:provider/provider.dart';
import '../../models/service.dart';
import '../../services/service_service.dart';
import '../../services/appointment_service.dart';
import '../../services/notification_service.dart';
import '../../services/availability_service.dart';
import '../../theme/app_theme.dart';
import 'my_appointments_screen.dart';
import 'payment_screen.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/slide_in_widget.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/animated_slot_chip.dart';
import '../../widgets/retry_button.dart';
import '../../utils/service_categories.dart';
import '../../utils/validators.dart';
import '../../utils/network_utils.dart';
import '../settings/cancellation_policy_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? preselectedProviderId;

  const BookAppointmentScreen({super.key, this.preselectedProviderId});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceService _serviceService = ServiceService();
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();
  final AvailabilityService _availabilityService = AvailabilityService();

  List<provider_model.Provider> _providers = [];
  List<Service> _services = [];
  Map<String, List<Service>> _servicesByCategory = {};
  provider_model.Provider? _selectedProvider;
  Service? _selectedService;
  String? _selectedCategory;
  DateTime? _selectedDate;
  String? _selectedSlot; // HH:MM
  List<String> _availableSlots = [];
  bool _loadingSlots = false;
  final _notesController = TextEditingController();
  bool _loading = false;
  bool _loadingProviders = true;
  bool _loadingServices = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await _serviceService.getProviders();
      setState(() {
        _providers = providers;
        _loadingProviders = false;
      });
      if (widget.preselectedProviderId != null && providers.isNotEmpty) {
        final match =
            providers.where((p) => p.id == widget.preselectedProviderId).toList();
        if (match.isNotEmpty) {
          setState(() {
            _selectedProvider = match.first;
          });
          await _loadServices(match.first.id);
        }
      }
    } catch (e) {
      setState(() {
        _loadingProviders = false;
        _error = NetworkUtils.getErrorMessage(e);
      });
    }
  }

  Future<void> _loadServices(String providerId) async {
    setState(() {
      _loadingServices = true;
      _selectedService = null;
      _selectedCategory = null;
      _selectedDate = null;
      _selectedSlot = null;
      _availableSlots = [];
      _error = null;
    });

    try {
      final services = await _serviceService.getServices(providerId: providerId);

      // Group services by category
      final Map<String, List<Service>> grouped = {};
      for (final service in services) {
        final category = service.category.isNotEmpty ? service.category : 'Other';
        grouped.putIfAbsent(category, () => []).add(service);
      }

      setState(() {
        _services = services;
        _servicesByCategory = grouped;
        _loadingServices = false;
      });
    } catch (e) {
      setState(() {
        _loadingServices = false;
        _error = NetworkUtils.getErrorMessage(e);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        final selected = DateTime(date.year, date.month, date.day);
        return !selected.isBefore(today);
      },
    );
    if (picked != null) {
      final validationError = Validators.futureDate(picked);
      if (validationError != null) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: colors.errorColor,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
        _availableSlots = [];
        _error = null;
      });
      await _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedProvider == null || _selectedService == null || _selectedDate == null) {
      return;
    }
    setState(() {
      _loadingSlots = true;
      _availableSlots = [];
      _selectedSlot = null;
      _error = null;
    });
    try {
      final slots = await _availabilityService.getAvailableTimeSlots(
        providerId: _selectedProvider!.id,
        serviceId: _selectedService!.id,
        date: _selectedDate!,
        slotInterval: 30,
      );
      setState(() {
        _availableSlots = slots;
        _loadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _loadingSlots = false;
        _error = 'Failed to load time slots: ${NetworkUtils.getErrorMessage(e)}';
      });
    }
  }

  Map<String, List<String>> _groupSlots(List<String> slots) {
    final morning = <String>[];
    final afternoon = <String>[];
    final evening = <String>[];
    for (final s in slots) {
      final parts = s.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      if (h < 12) {
        morning.add(s);
      } else if (h < 17) {
        afternoon.add(s);
      } else {
        evening.add(s);
      }
    }
    return {'Morning': morning, 'Afternoon': afternoon, 'Evening': evening};
  }

  Widget _slotSection({
    required String title,
    required List<String> slots,
    required ThemeColors colors,
    int startIndex = 0,
  }) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: colors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              final selected = _selectedSlot == slot;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + ((startIndex + index) * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: child,
                    ),
                  );
                },
                child: AnimatedSlotChip(
                  slot: slot,
                  selected: selected,
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context, slot);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    if (_selectedProvider == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a provider and service'),
          backgroundColor: colors.errorColor,
        ),
      );
      return;
    }
    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select date and a time slot'),
          backgroundColor: colors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = _selectedSlot!;

      final appointment = await _appointmentService.createAppointment(
        providerId: _selectedProvider!.id,
        serviceId: _selectedService!.id,
        date: dateStr,
        time: timeStr,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Schedule notification reminders
      try {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final selectedTime = TimeOfDay(hour: hour, minute: minute);
        final appointmentDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        final notificationId = appointment.id.hashCode.abs();

        final timeString =
            '${selectedTime.hour.toString().padLeft(2, "0")}:${selectedTime.minute.toString().padLeft(2, "0")}';

        await _notificationService.scheduleAppointmentReminder(
          id: notificationId,
          title: 'Appointment Reminder',
          body: 'You have an appointment with ${_selectedProvider!.name} tomorrow at $timeString',
          appointmentDate: appointmentDateTime,
          reminderBefore: const Duration(hours: 24),
        );

        await _notificationService.scheduleAppointmentReminder(
          id: notificationId + 1,
          title: 'Appointment Soon',
          body: 'Your appointment with ${_selectedProvider!.name} is in 2 hours',
          appointmentDate: appointmentDateTime,
          reminderBefore: const Duration(hours: 2),
        );
      } catch (e) {
        debugPrint('Failed to schedule notifications: $e');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(appointment: appointment),
          ),
        );
      }
    } catch (e) {
      final errorMessage = NetworkUtils.getErrorMessage(e);
      setState(() {
        _loading = false;
        _error = errorMessage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: colors.errorColor,
            behavior: SnackBarBehavior.floating,
            action: NetworkUtils.isRetryable(e)
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _submitBooking,
                  )
                : null,
          ),
        );
      }
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
        title: Text(
          'Book Appointment',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Provider Selection Section
                FadeInWidget(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: colors.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Step 1: Select Provider',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<provider_model.Provider>(
                        value: _selectedProvider,
                        decoration: InputDecoration(
                          labelText: 'Select Provider',
                          prefixIcon: Icon(Icons.person_outline, color: colors.primaryColor),
                          filled: true,
                          fillColor: colors.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colors.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colors.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colors.primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        hint: const Text('Choose a provider...'),
                        items: _providers.map((provider) {
                          return DropdownMenuItem<provider_model.Provider>(
                            value: provider,
                            child: Text(
                              provider.phone != null ? '${provider.name} (${provider.phone})' : provider.name,
                            ),
                          );
                        }).toList(),
                        onChanged: (provider_model.Provider? provider) {
                          setState(() {
                            _selectedProvider = provider;
                            _selectedService = null;
                            _error = null;
                          });
                          if (provider != null) {
                            _loadServices(provider.id);
                          }
                        },
                        validator: (value) => value == null ? 'Please select a provider' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ✅ FIXED: Service Selection Section (properly closed spread list)
                if (_selectedProvider != null) ...[
                  if (_loadingServices)
                    SlideInWidget(
                      offset: const Offset(0, 0.2),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryColor),
                          ),
                        ),
                      ),
                    )
                  else if (_services.isEmpty)
                    FadeInWidget(
                      child: LayeredCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: colors.warningColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No services available for this provider.',
                                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    FadeInWidget(
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: colors.primaryGradient,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Step 2: Select Service',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Category Tabs (if multiple categories)
                          if (_servicesByCategory.length > 1)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _servicesByCategory.keys.map((category) {
                                  final categoryInfo = ServiceCategories.getCategory(category);
                                  final isSelected = _selectedCategory == category;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            categoryInfo.icon,
                                            size: 16,
                                            color: isSelected ? Colors.white : categoryInfo.color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(category),
                                        ],
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = selected ? category : null;
                                          _selectedService = null;
                                          _error = null;
                                        });
                                      },
                                      selectedColor: categoryInfo.color,
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : colors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (_servicesByCategory.length > 1) const SizedBox(height: 16),

                          // Services grouped by category
                          ..._servicesByCategory.entries.map((entry) {
                            final category = entry.key;
                            final services = entry.value;

                            if (_selectedCategory != null && _selectedCategory != category) {
                              return const SizedBox.shrink();
                            }

                            final categoryInfo = ServiceCategories.getCategory(category);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedCategory == null && _servicesByCategory.length > 1) ...[
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: categoryInfo.color.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          categoryInfo.icon,
                                          color: categoryInfo.color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                ...services.map((service) {
                                  final isSelected = _selectedService?.id == service.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedService = service;
                                          _selectedDate = null;
                                          _selectedSlot = null;
                                          _availableSlots = [];
                                          _error = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colors.primaryColor.withOpacity(0.15)
                                              : colors.cardColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? colors.primaryColor : colors.borderColor,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: categoryInfo.color.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                categoryInfo.icon,
                                                color: categoryInfo.color,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    service.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: colors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    service.description,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: colors.textSecondary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$${service.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: colors.primaryColor,
                                                  ),
                                                ),
                                                Text(
                                                  '${service.duration} min',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              Icon(Icons.check_circle, color: colors.primaryColor, size: 24),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                if (_selectedCategory == null && _servicesByCategory.length > 1)
                                  const SizedBox(height: 20),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                // Service Details Card
                if (_selectedService != null) ...[
                  const SizedBox(height: 20),
                  SlideInWidget(
                    offset: const Offset(0, 0.2),
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: colors.primaryColor, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedService!.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedService!.description,
                            style: TextStyle(fontSize: 14, color: colors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: colors.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_selectedService!.duration} min',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.attach_money, size: 16, color: colors.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      '\$${_selectedService!.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Date & Time Selection Section
                if (_selectedService != null) ...[
                  FadeInWidget(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: colors.primaryGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Step 3: Select Date & Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.borderColor, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: colors.primaryColor, size: 22),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedDate != null
                                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                            : 'Select date',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedDate != null ? colors.textPrimary : colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: colors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Time Selection
                  FadeInWidget(
                    duration: const Duration(milliseconds: 700),
                    child: InkWell(
                      onTap: (_selectedDate == null)
                          ? null
                          : () async {
                              await _loadSlots();
                              if (!mounted) return;

                              final picked = await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) {
                                  return SafeArea(
                                    child: SizedBox(
                                      height: MediaQuery.of(ctx).size.height * 0.65,
                                      child: _loadingSlots
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(24),
                                                child: CircularProgressIndicator(),
                                              ),
                                            )
                                          : _availableSlots.isEmpty
                                              ? Padding(
                                                  padding: const EdgeInsets.all(20),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.event_busy, size: 48, color: colors.textSecondary),
                                                      const SizedBox(height: 12),
                                                      Text(
                                                        'No available slots for this date.',
                                                        style: TextStyle(
                                                          color: colors.textPrimary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Try another date or ask the provider to update availability.',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(color: colors.textSecondary),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          Navigator.pop(ctx);
                                                          await _selectDate();
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: colors.primaryColor,
                                                        ),
                                                        child: const Text('Pick another date'),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Builder(
                                                  builder: (ctx2) {
                                                    final grouped = _groupSlots(_availableSlots);
                                                    return ListView(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                'Select a time',
                                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                      fontWeight: FontWeight.bold,
                                                                      color: colors.textPrimary,
                                                                    ),
                                                              ),
                                                              IconButton(
                                                                tooltip: 'Refresh',
                                                                onPressed: () async {
                                                                  await _loadSlots();
                                                                  if (mounted) setState(() {});
                                                                },
                                                                icon: Icon(Icons.refresh, color: colors.primaryColor),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                                          child: Text(
                                                            '${_selectedService!.duration} min • \$${_selectedService!.price.toStringAsFixed(2)}',
                                                            style: TextStyle(color: colors.textSecondary),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        _slotSection(
                                                          title: 'Morning',
                                                          slots: grouped['Morning']!,
                                                          colors: colors,
                                                          startIndex: 0,
                                                        ),
                                                        _slotSection(
                                                          title: 'Afternoon',
                                                          slots: grouped['Afternoon']!,
                                                          colors: colors,
                                                          startIndex: grouped['Morning']!.length,
                                                        ),
                                                        _slotSection(
                                                          title: 'Evening',
                                                          slots: grouped['Evening']!,
                                                          colors: colors,
                                                          startIndex: grouped['Morning']!.length + grouped['Afternoon']!.length,
                                                        ),
                                                        const SizedBox(height: 18),
                                                      ],
                                                    );
                                                  },
                                                ),
                                    ),
                                  );
                                },
                              );

                              if (picked != null) {
                                setState(() => _selectedSlot = picked);
                              }
                            },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedDate == null ? colors.surfaceColor : colors.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              color: _selectedDate == null ? colors.textSecondary : colors.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time Slot',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDate == null
                                        ? 'Select date first'
                                        : _loadingSlots
                                            ? 'Loading slots...'
                                            : _availableSlots.isEmpty
                                                ? 'Tap to view slots'
                                                : (_selectedSlot ?? 'Select a slot'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedSlot != null ? colors.textPrimary : colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_loadingSlots)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(Icons.arrow_forward_ios, size: 16, color: colors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Notes Field
                if (_selectedService != null) ...[
                  FadeInWidget(
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: colors.primaryGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Step 4: Add Notes (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Any special requests or notes...',
                            prefixIcon: Icon(Icons.note_outlined, color: colors.primaryColor),
                            filled: true,
                            fillColor: colors.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: colors.primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],

                // Error Message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.errorColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.errorColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: colors.errorColor, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Cancellation Policy Link
                if (_selectedService != null) ...[
                  FadeInWidget(
                    duration: const Duration(milliseconds: 700),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CancellationPolicyScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.accentColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: colors.accentColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'View Cancellation & Refund Policy',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: colors.accentColor, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                if (_selectedService != null) ...[
                  FadeInWidget(
                    duration: const Duration(milliseconds: 800),
                    child: AnimatedButton(
                      text: 'Book Appointment',
                      icon: Icons.check_circle_outline,
                      isLoading: _loading,
                      onPressed: _loading ? null : _submitBooking,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
