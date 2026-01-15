import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointment_card.dart';
import '../../providers/auth_provider.dart';
import 'manage_services_screen.dart';
import '../customer/my_appointments_screen.dart';
import 'provider_location_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<Appointment> _recentAppointments = [];
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'confirmed': 0,
    'completed': 0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final appointments = await _appointmentService.getAppointments();
      setState(() {
        _recentAppointments = appointments.take(5).toList();
        _stats = {
          'total': appointments.length,
          'pending': appointments
              .where((a) => a.status == 'pending')
              .length,
          'confirmed': appointments
              .where((a) => a.status == 'confirmed')
              .length,
          'completed': appointments
              .where((a) => a.status == 'completed')
              .length,
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
            content: Text('Failed to load appointments: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ManageServicesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.work_outline),
                            label: const Text('Manage Services'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MyAppointmentsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('All Appointments'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProviderLocationScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('Set Location'),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Total',
                      _stats['total']!.toString(),
                      AppTheme.primaryColor,
                    ),
                    _buildStatCard(
                      'Pending',
                      _stats['pending']!.toString(),
                      AppTheme.warningColor,
                    ),
                    _buildStatCard(
                      'Confirmed',
                      _stats['confirmed']!.toString(),
                      AppTheme.accentColor,
                    ),
                    _buildStatCard(
                      'Completed',
                      _stats['completed']!.toString(),
                      AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Appointments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Appointments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyAppointmentsScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentAppointments.isEmpty)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._recentAppointments.map(
                  (apt) => AppointmentCard(
                    appointment: apt,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
