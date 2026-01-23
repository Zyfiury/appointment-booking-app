import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../../providers/theme_provider.dart';


class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Payment> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await _paymentService.getPayments();
      setState(() {
        _payments = payments;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load payments: $e';
      });
    }
  }

  Color _getStatusColor(String status, ThemeColors colors) {
    switch (status) {
      case 'completed':
        return colors.accentColor;
      case 'pending':
        return colors.warningColor;
      case 'failed':
        return colors.errorColor;
      case 'refunded':
        return colors.textSecondary;
      default:
        return colors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.undo;
      default:
        return Icons.payment;
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
        title: Text('Payment History'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
        ),
        child: _loading
            ? const ShimmerList(itemCount: 5)
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colors.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadPayments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryColor,
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No payments yet',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your payment history will appear here',
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPayments,
                        color: colors.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            return FadeInWidget(
                              duration: Duration(milliseconds: 200 + (index * 50)),
                              child: FloatingCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '\$${payment.amount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: colors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('MMM dd, yyyy • hh:mm a')
                                                    .format(payment.createdAt),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                    payment.status, colors)
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                      payment.status, colors)
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getStatusIcon(payment.status),
                                                size: 14,
                                                color: _getStatusColor(
                                                    payment.status, colors),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                payment.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusColor(
                                                      payment.status, colors),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.credit_card,
                                          size: 16,
                                          color: colors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          payment.paymentMethod.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.currency_exchange,
                                          size: 16,
                                          color: colors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          payment.currency.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (payment.transactionId != null) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.receipt,
                                            size: 16,
                                            color: colors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Transaction: ${payment.transactionId}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.textTertiary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
