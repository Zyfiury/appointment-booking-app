import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointment_card.dart';
import '../../services/review_service.dart';
import 'payment_screen.dart';
import 'review_screen.dart';
import '../../providers/theme_provider.dart';
import '../../services/availability_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/network_utils.dart';
import 'package:intl/intl.dart';


class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final ReviewService _reviewService = ReviewService();
  final AvailabilityService _availabilityService = AvailabilityService();
  List<Appointment> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    
    try {
      final appointments = await _appointmentService.getAppointments();
      if (!mounted) return;
      
      setState(() {
        _appointments = appointments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _loading = false;
      });
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        
        // Check if it's an authentication error
        final errorMessage = e.toString().toLowerCase();
        final isAuthError = errorMessage.contains('invalid token') || 
                           errorMessage.contains('unauthorized') ||
                           errorMessage.contains('401');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAuthError 
                ? 'Please log in to view appointments'
                : 'Failed to load appointments: $e'
            ),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Cancel Appointment',
      message: 'Are you sure you want to cancel this appointment? This action cannot be undone.',
      confirmText: 'Yes, Cancel',
      cancelText: 'No',
      confirmColor: colors.errorColor,
      icon: Icons.cancel_outlined,
    );

    if (confirmed == true) {
      try {
        await _appointmentService.updateAppointmentStatus(
          appointment.id,
          'cancelled',
        );
        _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment cancelled'),
              backgroundColor: colors.accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(NetworkUtils.getErrorMessage(e)),
              backgroundColor: colors.errorColor,
              action: NetworkUtils.isRetryable(e)
                  ? SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => _cancelAppointment(appointment),
                    )
                  : null,
            ),
          );
        }
      }
    }
  }

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    // Only customers + only pending (backend enforces too, but keep UX clean)
    if (appointment.status != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only pending appointments can be rescheduled.'),
          backgroundColor: colors.warningColor,
        ),
      );
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);

    List<String> slots = [];
    try {
      slots = await _availabilityService.getAvailableTimeSlots(
        providerId: appointment.provider.id,
        serviceId: appointment.service.id,
        date: pickedDate,
        slotInterval: 30,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load slots: $e'), backgroundColor: colors.errorColor),
      );
      return;
    }

    if (!mounted) return;
    final pickedSlot = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.65,
          child: slots.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: colors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No available slots for this date.',
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try another date.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (ctx, i) {
                    final slot = slots[i];
                    return ListTile(
                      title: Text(slot),
                      onTap: () => Navigator.pop(ctx, slot),
                    );
                  },
                ),
        ),
      ),
    );

    if (pickedSlot == null) return;

    try {
      await _appointmentService.rescheduleAppointment(
        appointmentId: appointment.id,
        date: dateStr,
        time: pickedSlot,
      );
      await _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Appointment rescheduled'), backgroundColor: colors.accentColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reschedule: $e'), backgroundColor: colors.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isProvider = user?.isProvider == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? 'All Appointments' : 'My Appointments'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Book your first appointment to get started',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _appointments[index];
                      return AppointmentCard(
                        appointment: appointment,
                        trailing: _buildActionButtons(appointment, isProvider, colors),
                      );
                    },
                  ),
      ),
    );
  }

  Widget? _buildActionButtons(Appointment appointment, bool isProvider, ThemeColors colors) {
    if (appointment.status == 'cancelled') {
      return null;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Customer actions
        if (!isProvider) ...[
          // Payment button for pending/confirmed appointments
          if (appointment.status == 'pending' || appointment.status == 'confirmed')
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      appointment: appointment,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payment, size: 16),
                  SizedBox(width: 4),
                  Text('Pay'),
                ],
              ),
            ),
          if (appointment.status == 'pending') ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _rescheduleAppointment(appointment),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16),
                  SizedBox(width: 4),
                  Text('Reschedule'),
                ],
              ),
            ),
          ],
          // Review button for completed appointments
          if (appointment.status == 'completed') ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                // Check if review already exists
                try {
                  final reviews = await _reviewService.getReviews(
                    providerId: appointment.provider.id,
                  );
                  final existingReview = reviews.firstWhere(
                    (r) => r.appointmentId == appointment.id,
                    orElse: () => reviews.first, // Dummy, won't match
                  );
                  
                  if (existingReview.appointmentId == appointment.id) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You have already reviewed this appointment'),
                          backgroundColor: colors.warningColor,
                        ),
                      );
                    }
                    return;
                  }
                } catch (e) {
                  // No review exists, proceed
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewScreen(
                      appointment: appointment,
                    ),
                  ),
                ).then((_) => _loadAppointments());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16),
                  SizedBox(width: 4),
                  Text('Review'),
                ],
              ),
            ),
          ],
        ],
        // Provider actions
        if (isProvider) ...[
        if (appointment.status == 'pending' && isProvider)
          ElevatedButton(
            onPressed: () async {
              try {
                await _appointmentService.updateAppointmentStatus(
                  appointment.id,
                  'confirmed',
                );
                _loadAppointments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment confirmed'),
                      backgroundColor: colors.accentColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to confirm appointment: $e'),
                      backgroundColor: colors.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: Text('Confirm'),
          ),
        if (appointment.status == 'confirmed' && isProvider)
          ElevatedButton(
            onPressed: () async {
              try {
                await _appointmentService.updateAppointmentStatus(
                  appointment.id,
                  'completed',
                );
                _loadAppointments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment marked as completed'),
                      backgroundColor: colors.accentColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update appointment: $e'),
                      backgroundColor: colors.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: Text('Mark Completed'),
          ),
          const SizedBox(width: 8),
        ],
        // Cancel button (for both)
        if (appointment.status != 'completed' && appointment.status != 'cancelled')
          OutlinedButton(
            onPressed: () => _cancelAppointment(appointment),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.errorColor,
              side: BorderSide(color: colors.errorColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Cancel'),
          ),
      ],
    );
  }
}
