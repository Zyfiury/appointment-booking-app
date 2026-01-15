import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import 'my_appointments_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appointment;

  const PaymentScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  bool _validateCardNumber(String cardNumber) {
    // Remove spaces and dashes
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    // Check if it's 13-19 digits (standard card length)
    if (cleaned.length < 13 || cleaned.length > 19) {
      return false;
    }
    // Luhn algorithm check
    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int n = int.parse(cleaned[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10) == 0;
  }

  bool _validateExpiry(String expiry) {
    // Format: MM/YY
    final parts = expiry.split('/');
    if (parts.length != 2) return false;
    
    try {
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      
      if (month < 1 || month > 12) return false;
      
      // Convert YY to full year (assuming 20XX)
      final fullYear = 2000 + year;
      final now = DateTime.now();
      final expiryDate = DateTime(fullYear, month + 1, 0); // Last day of month
      
      return expiryDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  bool _validateCVC(String cvc) {
    // CVC is 3-4 digits
    return RegExp(r'^\d{3,4}$').hasMatch(cvc);
  }

  String _formatCardNumber(String input) {
    // Remove all non-digits
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    // Add spaces every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String input) {
    // Remove all non-digits
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 2) {
      return '${digitsOnly.substring(0, 2)}/${digitsOnly.length > 2 ? digitsOnly.substring(2, 4) : ''}';
    }
    return digitsOnly;
  }

  Future<void> _processPayment() async {
    // Validate card number
    final cardNumber = _cardNumberController.text.replaceAll(RegExp(r'[\s-]'), '');
    if (!_validateCardNumber(cardNumber)) {
      setState(() {
        _error = 'Please enter a valid card number';
      });
      return;
    }

    // Validate expiry
    if (!_validateExpiry(_expiryController.text)) {
      setState(() {
        _error = 'Please enter a valid expiry date (MM/YY)';
      });
      return;
    }

    // Validate CVC
    if (!_validateCVC(_cvcController.text)) {
      setState(() {
        _error = 'Please enter a valid CVC (3-4 digits)';
      });
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      // Create payment intent
      final paymentIntent = await _paymentService.createPaymentIntent(
        appointmentId: widget.appointment.id,
        amount: widget.appointment.service.price,
      );

      // In production, integrate with Stripe SDK here
      // For now, simulate payment confirmation with validation
      await Future.delayed(const Duration(seconds: 2));

      // Confirm payment on backend
      final payment = await _paymentService.confirmPayment(
        paymentIntentId: paymentIntent['id'] ?? paymentIntent['paymentId'],
        paymentMethodId: 'card',
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment successful! \$${payment.amount.toStringAsFixed(2)} paid',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to appointments
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Payment failed: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Payment'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Appointment Summary
              FadeInWidget(
                child: FloatingCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.appointment.service.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${widget.appointment.service.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provider: ${widget.appointment.provider.name}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Payment Form
              FadeInWidget(
                duration: const Duration(milliseconds: 300),
                child: FloatingCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          hintText: '1234 5678 9012 3456',
                          filled: true,
                          fillColor: AppTheme.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.credit_card,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onChanged: (value) {
                          // Format card number as user types
                          final formatted = _formatCardNumber(value);
                          if (formatted != value) {
                            _cardNumberController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          }
                        },
                        maxLength: 19, // 16 digits + 3 spaces
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expiryController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'MM/YY',
                                hintText: '12/25',
                                filled: true,
                                fillColor: AppTheme.surfaceColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {
                                // Format expiry as user types
                                final formatted = _formatExpiry(value);
                                if (formatted != value) {
                                  _expiryController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                                }
                              },
                              maxLength: 5,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _cvcController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'CVC',
                                hintText: '123',
                                filled: true,
                                fillColor: AppTheme.surfaceColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              maxLength: 4,
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.errorColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Pay Button
              FadeInWidget(
                duration: const Duration(milliseconds: 400),
                child: AnimatedButton(
                  text: 'Pay \$${widget.appointment.service.price.toStringAsFixed(2)}',
                  icon: Icons.payment,
                  isLoading: _processing,
                  onPressed: _processing ? null : _processPayment,
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // Test Card Info (Development)
              if (!AppConfig.isProduction)
                FadeInWidget(
                  duration: const Duration(milliseconds: 500),
                  child: LayeredCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.warningColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Test Mode',
                              style: TextStyle(
                                color: AppTheme.warningColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use test card: 4242 4242 4242 4242\nExpiry: Any future date (e.g., 12/25)\nCVC: Any 3 digits (e.g., 123)',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Security Note
              FadeInWidget(
                duration: const Duration(milliseconds: 500),
                child: LayeredCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your payment is secure and encrypted',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
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
