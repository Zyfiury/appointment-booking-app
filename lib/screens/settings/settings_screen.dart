import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;
    final currentColors = AppTheme.getColors(themeProvider.currentTheme);

    return Scaffold(
      backgroundColor: currentColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Settings'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: currentColors.backgroundGradient,
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
                        gradient: currentColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: user?.profilePicture != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user!.profilePicture!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: currentColors.primaryColor.withOpacity(0.3),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: currentColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: currentColors.textSecondary,
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
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentColors.textPrimary,
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
                      Divider(height: 32),
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
                      Divider(height: 32),
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
                      Divider(height: 32),
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
            // Theme Selection Section
            FadeInWidget(
              duration: const Duration(milliseconds: 250),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final currentThemeColors = AppTheme.getColors(themeProvider.currentTheme);
                        return Column(
                          children: [
                            _buildThemeOption(
                              context: context,
                              themeProvider: themeProvider,
                              theme: AppThemeMode.darkProfessional,
                              colors: AppTheme.darkProfessional,
                              currentColors: currentThemeColors,
                            ),
                            const SizedBox(height: 12),
                            _buildThemeOption(
                              context: context,
                              themeProvider: themeProvider,
                              theme: AppThemeMode.darkElegant,
                              colors: AppTheme.darkElegant,
                              currentColors: currentThemeColors,
                            ),
                            const SizedBox(height: 12),
                            _buildThemeOption(
                              context: context,
                              themeProvider: themeProvider,
                              theme: AppThemeMode.lightProfessional,
                              colors: AppTheme.lightProfessional,
                              currentColors: currentThemeColors,
                            ),
                            const SizedBox(height: 12),
                            _buildThemeOption(
                              context: context,
                              themeProvider: themeProvider,
                              theme: AppThemeMode.lightWarm,
                              colors: AppTheme.lightWarm,
                              currentColors: currentThemeColors,
                            ),
                          ],
                        );
                      },
                    ),
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
                        Navigator.pushNamed(context, '/edit-profile');
                      },
                    ),
                    Divider(height: 32),
                    _buildSettingsTile(
                      title: 'Help & Support',
                      icon: Icons.help_outline,
                      onTap: () {
                        Navigator.pushNamed(context, '/help-support');
                      },
                    ),
                    Divider(height: 32),
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
                              gradient: currentColors.primaryGradient,
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
                      backgroundColor: currentColors.cardColor,
                      title: Text(
                        'Logout',
                        style: TextStyle(color: currentColors.textPrimary),
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: currentColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: currentColors.errorColor,
                          ),
                          child: Text('Logout'),
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
                      color: currentColors.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: currentColors.errorColor,
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

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required AppThemeMode theme,
    required ThemeColors colors,
    required ThemeColors currentColors,
  }) {
    final isSelected = themeProvider.currentTheme == theme;
    
    return InkWell(
      onTap: () {
        themeProvider.setTheme(theme);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryColor.withOpacity(0.15)
              : currentColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primaryColor : currentColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Color Preview
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: colors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        themeProvider.getThemeName(theme),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colors.primaryColor
                              : currentColors.textPrimary,
                        ),
                      ),
                      if (theme == AppThemeMode.darkProfessional ||
                          theme == AppThemeMode.darkElegant) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                            decoration: BoxDecoration(
                            color: currentColors.textTertiary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Dark',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: currentColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      if (theme == AppThemeMode.lightProfessional ||
                          theme == AppThemeMode.lightWarm) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.textTertiary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Light',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    themeProvider.getThemeDescription(theme),
                    style: TextStyle(
                      fontSize: 13,
                      color: currentColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.primaryColor,
                size: 24,
              ),
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
