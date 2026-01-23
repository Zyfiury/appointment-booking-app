import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../providers/theme_provider.dart';
import '../../services/support_service.dart';
import '../../utils/network_utils.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final SupportService _supportService = SupportService();
  String? _selectedCategory;
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await _supportService.contactSupport(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        category: _selectedCategory,
      );

      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Support request submitted. We\'ll get back to you soon.'),
            backgroundColor: colors.accentColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkUtils.getErrorMessage(e)),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
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
        title: const Text('Contact Support'),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FadeInWidget(
                child: FloatingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: colors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.support_agent, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'How can we help?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'technical', child: Text('Technical Issue')),
                          DropdownMenuItem(value: 'billing', child: Text('Billing')),
                          DropdownMenuItem(value: 'report', child: Text('Report Issue')),
                        ],
                        onChanged: (value) => setState(() => _selectedCategory = value),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.subject),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Subject must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Message *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return 'Message must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitSupportRequest,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Submit Request'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
