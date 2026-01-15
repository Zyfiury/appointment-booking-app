import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
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

  Future<void> _processPayment() async {
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvcController.text.isEmpty) {
      setState(() {
        _error = 'Please enter valid card details';
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
      // For now, simulate payment confirmation
      await Future.delayed(const Duration(seconds: 2));

      // Confirm payment on backend
      await _paymentService.confirmPayment(
        paymentIntentId: paymentIntent['id'] ?? paymentIntent['paymentId'],
        paymentMethodId: 'card',
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MyAppointmentsScreen(),
          ),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Payment failed: ${e.toString()}';
      });
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
                        ),
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
                              ),
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
