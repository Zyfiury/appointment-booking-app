import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Section
            FadeInWidget(
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Notifications Section
            FadeInWidget(
              duration: const Duration(milliseconds: 200),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSwitchTile(
                      title: 'Enable Notifications',
                      subtitle: 'Receive notifications about your appointments',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSetting('notifications_enabled', value);
                      },
                      icon: Icons.notifications_outlined,
                    ),
                    if (_notificationsEnabled) ...[
                      const Divider(height: 32),
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Get instant notifications on your device',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                          _saveSetting('push_notifications', value);
                        },
                        icon: Icons.phone_android_outlined,
                      ),
                      const Divider(height: 32),
                      _buildSwitchTile(
                        title: 'Email Notifications',
                        subtitle: 'Receive updates via email',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                          _saveSetting('email_notifications', value);
                        },
                        icon: Icons.email_outlined,
                      ),
                      const Divider(height: 32),
                      _buildSwitchTile(
                        title: 'Appointment Reminders',
                        subtitle: 'Get reminded before your appointments',
                        value: _reminderEnabled,
                        onChanged: (value) {
                          setState(() {
                            _reminderEnabled = value;
                          });
                          _saveSetting('reminder_enabled', value);
                        },
                        icon: Icons.alarm_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Account Section
            FadeInWidget(
              duration: const Duration(milliseconds: 300),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      title: 'Edit Profile',
                      icon: Icons.person_outline,
                      onTap: () {
                        // TODO: Navigate to edit profile
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit Profile - Coming Soon'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),
                    _buildSettingsTile(
                      title: 'Help & Support',
                      icon: Icons.help_outline,
                      onTap: () {
                        // TODO: Navigate to help
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help & Support - Coming Soon'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),
                    _buildSettingsTile(
                      title: 'About',
                      icon: Icons.info_outline,
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Bookly',
                          applicationVersion: '1.0.0',
                          applicationIcon: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Logout Button
            FadeInWidget(
              duration: const Duration(milliseconds: 400),
              child: LayeredCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.cardColor,
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
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

                  if (confirm == true) {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
