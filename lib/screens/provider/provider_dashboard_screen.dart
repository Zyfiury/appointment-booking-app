import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/appointment_service.dart';
import '../../services/service_service.dart';
import '../../services/payment_service.dart';
import '../../models/appointment.dart';
import '../../models/payment.dart';
import '../../models/service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/layered_card.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/provider_onboarding_checklist.dart';
import 'manage_services_screen.dart';
import '../customer/my_appointments_screen.dart';
import 'provider_location_screen.dart';
import 'provider_availability_screen.dart';
import '../../providers/theme_provider.dart';


class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final ServiceService _serviceService = ServiceService();
  final PaymentService _paymentService = PaymentService();
  
  List<Appointment> _recentAppointments = [];
  List<Service> _services = [];
  List<Payment> _payments = [];
  
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'confirmed': 0,
    'completed': 0,
  };
  
  double _totalEarnings = 0.0;
  int _serviceCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final providerId = authProvider.user?.id;

      // Load data in parallel
      final results = await Future.wait([
        _appointmentService.getAppointments(),
        providerId != null ? _serviceService.getServices(providerId: providerId) : Future.value(<Service>[]),
        _paymentService.getPayments(),
      ]);

      final allAppointments = results[0] as List<Appointment>;
      final services = results[1] as List<Service>;
      final allPayments = results[2] as List<Payment>;

      // Filter appointments to only show this provider's appointments (safety check)
      final appointments = allAppointments.where((a) => a.provider.id == providerId).toList();
      
      // Filter payments to only show payments for this provider's appointments
      final providerAppointmentIds = appointments.map((a) => a.id).toSet();
      final payments = allPayments.where((p) => 
        providerAppointmentIds.contains(p.appointmentId)
      ).toList();

      // Calculate earnings from completed payments
      final providerPayments = payments.where((p) => 
        p.status == 'completed' && p.providerAmount > 0
      ).toList();
      final earnings = providerPayments.fold<double>(
        0.0, 
        (sum, p) => sum + p.providerAmount
      );

      setState(() {
        _recentAppointments = appointments.take(5).toList();
        _services = services;
        _payments = payments;
        _serviceCount = services.length;
        _totalEarnings = earnings;
        _stats = {
          'total': appointments.length,
          'pending': appointments.where((a) => a.status == 'pending').length,
          'confirmed': appointments.where((a) => a.status == 'confirmed').length,
          'completed': appointments.where((a) => a.status == 'completed').length,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to load dashboard: $e')),
              ],
            ),
            backgroundColor: colors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
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

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Provider Dashboard',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings, size: 20),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: colors.primaryColor,
          backgroundColor: colors.cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Onboarding Checklist (if incomplete)
                const ProviderOnboardingChecklist(),
                // Welcome Card (Top Layer)
                FadeInWidget(
                  duration: const Duration(milliseconds: 600),
                  child: FloatingCard(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: colors.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.business_center,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.name ?? 'Provider',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Earnings',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${_totalEarnings.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colors.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: colors.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Services',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _serviceCount.toString(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primaryColor,
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

                // Quick Actions (Layered Cards)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      FadeInWidget(
                        duration: const Duration(milliseconds: 700),
                        child: AnimatedButton(
                          text: 'Manage Services',
                          icon: Icons.work_outline,
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const ManageServicesScreen(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          backgroundColor: colors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FadeInWidget(
                              duration: const Duration(milliseconds: 800),
                              child: LayeredCard(
                                margin: EdgeInsets.zero,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          const MyAppointmentsScreen(),
                                      transitionsBuilder:
                                          (context, animation, secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: colors.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Appointments',
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FadeInWidget(
                              duration: const Duration(milliseconds: 900),
                              child: LayeredCard(
                                margin: EdgeInsets.zero,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProviderLocationScreen(),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: colors.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Location',
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FadeInWidget(
                        duration: const Duration(milliseconds: 950),
                        child: AnimatedButton(
                          text: 'Set Availability',
                          icon: Icons.schedule,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProviderAvailabilityScreen(),
                              ),
                            );
                          },
                          backgroundColor: colors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FadeInWidget(
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment Stats',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total',
                                _stats['total']!.toString(),
                                Icons.calendar_view_month,
                                colors.primaryColor,
                                0,
                                colors,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Pending',
                                _stats['pending']!.toString(),
                                Icons.pending_actions,
                                colors.warningColor,
                                1,
                                colors,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Confirmed',
                                _stats['confirmed']!.toString(),
                                Icons.check_circle_outline,
                                colors.accentColor,
                                2,
                                colors,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Completed',
                                _stats['completed']!.toString(),
                                Icons.done_all,
                                Colors.green,
                                3,
                                colors,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Recent Appointments Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FadeInWidget(
                        duration: const Duration(milliseconds: 1100),
                        child: Text(
                          'Recent Appointments',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                        ),
                      ),
                      FadeInWidget(
                        duration: const Duration(milliseconds: 1200),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const MyAppointmentsScreen(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: Text('View All'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Appointments List
                if (_loading)
                  const ShimmerList(itemCount: 3, itemHeight: 180)
                else if (_recentAppointments.isEmpty)
                  FadeInWidget(
                    child: FloatingCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.primaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: colors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No appointments yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your upcoming appointments will appear here',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._recentAppointments.asMap().entries.map(
                        (entry) => AppointmentCard(
                          appointment: entry.value,
                          index: entry.key,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const MyAppointmentsScreen(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, int index, ThemeColors colors) {
    return FadeInWidget(
      duration: Duration(milliseconds: 1000 + (index * 100)),
      child: FloatingCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}