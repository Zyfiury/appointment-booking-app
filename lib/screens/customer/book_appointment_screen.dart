import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/provider.dart';
import '../../models/service.dart';
import '../../services/service_service.dart';
import '../../services/appointment_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import 'my_appointments_screen.dart';
import 'payment_screen.dart';

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

  List<Provider> _providers = [];
  List<Service> _services = [];
  Provider? _selectedProvider;
  Service? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();
  bool _loading = false;
  bool _loadingProviders = true;
  bool _loadingServices = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    if (widget.preselectedProviderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = _providers.firstWhere(
          (p) => p.id == widget.preselectedProviderId,
          orElse: () => _providers.first,
        );
        if (provider.id == widget.preselectedProviderId) {
          setState(() {
            _selectedProvider = provider;
          });
          _loadServices(provider.id);
        }
      });
    }
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
    } catch (e) {
      setState(() {
        _loadingProviders = false;
        _error = 'Failed to load providers';
      });
    }
  }

  Future<void> _loadServices(String providerId) async {
    setState(() {
      _loadingServices = true;
      _selectedService = null;
    });

    try {
      final services = await _serviceService.getServices(providerId: providerId);
      setState(() {
        _services = services;
        _loadingServices = false;
      });
    } catch (e) {
      setState(() {
        _loadingServices = false;
        _error = 'Failed to load services';
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvider == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a provider and service'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: AppTheme.errorColor,
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
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final appointment = await _appointmentService.createAppointment(
        providerId: _selectedProvider!.id,
        serviceId: _selectedService!.id,
        date: dateStr,
        time: timeStr,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Schedule notification reminders
      try {
        final appointmentDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final notificationId = appointment.id.hashCode.abs();

        // Schedule 24 hour reminder
        await _notificationService.scheduleAppointmentReminder(
          id: notificationId,
          title: 'Appointment Reminder',
          body: 'You have an appointment with ${_selectedProvider!.name} tomorrow at ${_selectedTime!.format(context)}',
          appointmentDate: appointmentDateTime,
          reminderBefore: const Duration(hours: 24),
        );

        // Schedule 2 hour reminder
        await _notificationService.scheduleAppointmentReminder(
          id: notificationId + 1,
          title: 'Appointment Soon',
          body: 'Your appointment with ${_selectedProvider!.name} is in 2 hours',
          appointmentDate: appointmentDateTime,
          reminderBefore: const Duration(hours: 2),
        );
      } catch (e) {
        // Notification scheduling failed, but appointment was created
        // Log error but don't block the user
        debugPrint('Failed to schedule notifications: $e');
      }

      if (mounted) {
        // Navigate to payment screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              appointment: appointment,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to book appointment. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Provider Selection
              DropdownButtonFormField<Provider>(
                value: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'Select Provider',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                hint: const Text('Choose a provider...'),
                items: _providers.map((provider) {
                  return DropdownMenuItem<Provider>(
                    value: provider,
                    child: Text(
                      provider.phone != null
                          ? '${provider.name} (${provider.phone})'
                          : provider.name,
                    ),
                  );
                }).toList(),
                onChanged: (provider) {
                  setState(() {
                    _selectedProvider = provider;
                    _selectedService = null;
                  });
                  if (provider != null) {
                    _loadServices(provider.id);
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a provider';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Service Selection
              if (_selectedProvider != null) ...[
                if (_loadingServices)
                  const Center(child: CircularProgressIndicator())
                else if (_services.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No services available for this provider.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<Service>(
                    value: _selectedService,
                    decoration: const InputDecoration(
                      labelText: 'Select Service',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    hint: const Text('Choose a service...'),
                    items: _services.map((service) {
                      return DropdownMenuItem<Service>(
                        value: service,
                        child: Text(
                          '${service.name} - \$${service.price.toStringAsFixed(2)} (${service.duration} min)',
                        ),
                      );
                    }).toList(),
                    onChanged: (service) {
                      setState(() {
                        _selectedService = service;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a service';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
              ],

              // Service Details Card
              if (_selectedService != null) ...[
                Card(
                  color: AppTheme.backgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedService!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedService!.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedService!.duration} minutes',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 24),
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${_selectedService!.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Date Selection
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Selection
              InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select time',
                    style: TextStyle(
                      color: _selectedTime != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any special requests or notes...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),

              // Submit Button
              ElevatedButton(
                onPressed: _loading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
