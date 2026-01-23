import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/availability.dart';
import '../../models/availability_exception.dart';
import '../../providers/theme_provider.dart';
import '../../services/availability_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/layered_card.dart';

class ProviderAvailabilityScreen extends StatefulWidget {
  const ProviderAvailabilityScreen({super.key});

  @override
  State<ProviderAvailabilityScreen> createState() => _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState extends State<ProviderAvailabilityScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();

  static const _days = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  bool _loading = true;
  String? _error;
  final Map<String, Availability> _byDay = {};
  List<AvailabilityException> _exceptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _availabilityService.getMyAvailability();
      final exceptions = await _availabilityService.getMyExceptions();
      _byDay.clear();
      for (final a in rows) {
        _byDay[a.dayOfWeek] = a;
      }
      // Seed defaults for missing days (not available)
      for (final day in _days) {
        _byDay.putIfAbsent(
          day,
          () => Availability(
            id: '',
            providerId: '',
            dayOfWeek: day,
            startTime: '09:00',
            endTime: '17:00',
            breaks: const [],
            isAvailable: false,
          ),
        );
      }
      setState(() {
        _exceptions = exceptions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load availability: $e';
      });
    }
  }

  Future<void> _addOrEditException({AvailabilityException? existing}) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    DateTime initial = DateTime.now().add(const Duration(days: 1));
    if (existing != null) {
      try {
        initial = DateTime.parse(existing.date);
      } catch (_) {}
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final dateStr =
        '${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

    bool isAvailable = existing?.isAvailable ?? false; // default: day off
    String? startTime = existing?.startTime ?? '09:00';
    String? endTime = existing?.endTime ?? '17:00';
    final noteController = TextEditingController(text: existing?.note ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add date exception' : 'Edit date exception'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: $dateStr', style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available on this date'),
                value: isAvailable,
                onChanged: (v) => setLocal(() => isAvailable = v),
              ),
              if (isAvailable) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await _pickTime(startTime ?? '09:00');
                          if (t == null) return;
                          setLocal(() => startTime = t);
                        },
                        child: Text('Start: ${startTime ?? '--:--'}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await _pickTime(endTime ?? '17:00');
                          if (t == null) return;
                          setLocal(() => endTime = t);
                        },
                        child: Text('End: ${endTime ?? '--:--'}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result != true) return;

    try {
      await _availabilityService.createOrUpdateException(
        date: dateStr,
        isAvailable: isAvailable,
        startTime: isAvailable ? startTime : null,
        endTime: isAvailable ? endTime : null,
        breaks: existing?.breaks ?? const [],
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Exception saved'), backgroundColor: colors.accentColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save exception: $e'), backgroundColor: colors.errorColor),
        );
      }
    }
  }

  Future<void> _deleteException(AvailabilityException ex) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    try {
      await _availabilityService.deleteException(ex.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Exception deleted'), backgroundColor: colors.accentColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: colors.errorColor),
        );
      }
    }
  }

  Future<void> _saveDay(String day, Availability updated) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    try {
      final saved = await _availabilityService.createOrUpdateAvailability(
        dayOfWeek: updated.dayOfWeek,
        startTime: updated.startTime,
        endTime: updated.endTime,
        breaks: updated.breaks,
        isAvailable: updated.isAvailable,
      );
      setState(() {
        _byDay[day] = saved;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Availability saved'),
            backgroundColor: colors.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    }
  }

  Future<String?> _pickTime(String initial) async {
    final parts = initial.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  String _prettyDay(String day) => '${day[0].toUpperCase()}${day.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          IconButton(
            tooltip: 'Add date exception',
            onPressed: _loading ? null : () => _addOrEditException(),
            icon: const Icon(Icons.event_available),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyState(
                    title: 'Couldn’t load availability',
                    message: 'Check your connection and try again.\n\n$_error',
                    fallbackIcon: Icons.wifi_off_rounded,
                    actionText: 'Retry',
                    onAction: _load,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      FadeInWidget(
                        duration: const Duration(milliseconds: 400),
                        child: FloatingCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: colors.primaryGradient,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Date Exceptions',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _addOrEditException(),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_exceptions.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.event_busy, size: 48, color: colors.textSecondary.withOpacity(0.5)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No exceptions yet',
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add a day off or special hours',
                                          style: TextStyle(
                                            color: colors.textTertiary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ..._exceptions.take(10).asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final ex = entry.value;
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 200 + (index * 50)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 10 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: ex.isAvailable 
                                            ? colors.primaryColor.withOpacity(0.1)
                                            : colors.errorColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: ex.isAvailable 
                                              ? colors.primaryColor.withOpacity(0.3)
                                              : colors.errorColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            ex.isAvailable ? Icons.access_time : Icons.event_busy,
                                            color: ex.isAvailable ? colors.primaryColor : colors.errorColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ex.date,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: colors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  ex.isAvailable
                                                      ? 'Special hours: ${ex.startTime ?? '--:--'}-${ex.endTime ?? '--:--'}${ex.note != null ? ' • ${ex.note}' : ''}'
                                                      : 'Day off${ex.note != null ? ' • ${ex.note}' : ''}',
                                                  style: TextStyle(
                                                    color: colors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Edit',
                                            onPressed: () => _addOrEditException(existing: ex),
                                            icon: Icon(Icons.edit, color: colors.primaryColor, size: 20),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            onPressed: () => _deleteException(ex),
                                            icon: Icon(Icons.delete_outline, color: colors.errorColor, size: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._days.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final current = _byDay[day]!;
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FloatingCard(
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: current.isAvailable 
                                                  ? colors.primaryGradient 
                                                  : LinearGradient(
                                                      colors: [
                                                        colors.textSecondary.withOpacity(0.3),
                                                        colors.textSecondary.withOpacity(0.2),
                                                      ],
                                                    ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _prettyDay(day).substring(0, 2).toUpperCase(),
                                                style: TextStyle(
                                                  color: current.isAvailable ? Colors.white : colors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _prettyDay(day),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Switch(
                                          value: current.isAvailable,
                                          activeColor: colors.primaryColor,
                                          onChanged: (v) async {
                                            final updated = Availability(
                                              id: current.id,
                                              providerId: current.providerId,
                                              dayOfWeek: current.dayOfWeek,
                                              startTime: current.startTime,
                                              endTime: current.endTime,
                                              breaks: current.breaks,
                                              isAvailable: v,
                                            );
                                            await _saveDay(day, updated);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  AnimatedOpacity(
                                    opacity: current.isAvailable ? 1.0 : 0.5,
                                    duration: const Duration(milliseconds: 200),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colors.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colors.primaryColor.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: current.isAvailable
                                                    ? () async {
                                                        final t = await _pickTime(current.startTime);
                                                        if (t == null) return;
                                                        final updated = Availability(
                                                          id: current.id,
                                                          providerId: current.providerId,
                                                          dayOfWeek: current.dayOfWeek,
                                                          startTime: t,
                                                          endTime: current.endTime,
                                                          breaks: current.breaks,
                                                          isAvailable: current.isAvailable,
                                                        );
                                                        await _saveDay(day, updated);
                                                      }
                                                    : null,
                                                borderRadius: BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.play_arrow, color: colors.primaryColor, size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Start: ${current.startTime}',
                                                        style: TextStyle(
                                                          color: colors.primaryColor,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colors.errorColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colors.errorColor.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: current.isAvailable
                                                    ? () async {
                                                        final t = await _pickTime(current.endTime);
                                                        if (t == null) return;
                                                        final updated = Availability(
                                                          id: current.id,
                                                          providerId: current.providerId,
                                                          dayOfWeek: current.dayOfWeek,
                                                          startTime: current.startTime,
                                                          endTime: t,
                                                          breaks: current.breaks,
                                                          isAvailable: current.isAvailable,
                                                        );
                                                        await _saveDay(day, updated);
                                                      }
                                                    : null,
                                                borderRadius: BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.stop, color: colors.errorColor, size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'End: ${current.endTime}',
                                                        style: TextStyle(
                                                          color: colors.errorColor,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedOpacity(
                                    opacity: current.isAvailable ? 1.0 : 0.5,
                                    duration: const Duration(milliseconds: 200),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.coffee, size: 16, color: colors.textSecondary),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Breaks',
                                                  style: TextStyle(
                                                    color: colors.textSecondary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton.icon(
                                              onPressed: current.isAvailable
                                                  ? () async {
                                                      final controller = TextEditingController();
                                                      final newBreak = await showDialog<String>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text('Add Break'),
                                                          content: TextField(
                                                            controller: controller,
                                                            decoration: const InputDecoration(
                                                              hintText: 'HH:MM-HH:MM  (e.g., 12:00-13:00)',
                                                              prefixIcon: Icon(Icons.access_time),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx),
                                                              child: const Text('Cancel'),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                                              child: const Text('Add'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (newBreak == null || newBreak.isEmpty) return;
                                                      final updated = Availability(
                                                        id: current.id,
                                                        providerId: current.providerId,
                                                        dayOfWeek: current.dayOfWeek,
                                                        startTime: current.startTime,
                                                        endTime: current.endTime,
                                                        breaks: [...current.breaks, newBreak],
                                                        isAvailable: current.isAvailable,
                                                      );
                                                      await _saveDay(day, updated);
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.add, size: 16),
                                              label: const Text('Add'),
                                            ),
                                          ],
                                        ),
                                        if (current.breaks.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'No breaks scheduled',
                                              style: TextStyle(
                                                color: colors.textTertiary,
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        else
                                          ...current.breaks.asMap().entries.map((entry) {
                                            final breakIndex = entry.key;
                                            final breakTime = entry.value;
                                            return Container(
                                              margin: const EdgeInsets.only(top: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: colors.surfaceColor,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.schedule, size: 14, color: colors.textSecondary),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    breakTime,
                                                    style: TextStyle(
                                                      color: colors.textPrimary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    icon: Icon(Icons.close, size: 16, color: colors.errorColor),
                                                    onPressed: current.isAvailable
                                                        ? () async {
                                                            final updated = Availability(
                                                              id: current.id,
                                                              providerId: current.providerId,
                                                              dayOfWeek: current.dayOfWeek,
                                                              startTime: current.startTime,
                                                              endTime: current.endTime,
                                                              breaks: current.breaks.where((b) => b != breakTime).toList(),
                                                              isAvailable: current.isAvailable,
                                                            );
                                                            await _saveDay(day, updated);
                                                          }
                                                        : null,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
      ),
    );
  }
}

