import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_snackbar.dart';
import 'package:itc_events/app/widgets/loading_view.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/event_payment.dart';
import 'package:itc_events/modules/tickets/khqr_card.dart';
import 'package:itc_events/modules/tickets/payment_method.dart';
import 'package:itc_events/modules/tickets/payment_success_page.dart';
import 'package:itc_events/modules/tickets/ticket_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class KhqrCheckoutPage extends StatefulWidget {
  const KhqrCheckoutPage({
    super.key,
    required this.event,
    this.method = PaymentMethodOption.khqr,
  });

  final Event event;
  final String method;

  @override
  State<KhqrCheckoutPage> createState() => _KhqrCheckoutPageState();
}

class _KhqrCheckoutPageState extends State<KhqrCheckoutPage> {
  EventPayment? _payment;
  String? _error;
  bool _loading = true;
  bool _checking = false;
  bool _qrExpired = false;
  String _countdown = '';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  TicketController get _tickets => Get.find<TicketController>();

  bool get _isAbaPay => widget.method == PaymentMethodOption.abaPay;

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
      _qrExpired = false;
      _checking = false;
    });
    _countdownTimer?.cancel();

    final payment = await _tickets.startPayment(
      widget.event,
      method: widget.method,
    );
    if (!mounted) return;

    if (payment == null) {
      setState(() {
        _loading = false;
        _error = 'could_not_start_payment'.tr;
      });
      return;
    }

    if (payment.isPaid && payment.ticket != null) {
      _goToSuccess(payment.ticket!.id);
      return;
    }

    setState(() {
      _payment = payment;
      _loading = false;
    });
    _startCountdown();
  }

  Future<void> _confirmPaid({bool quiet = false}) async {
    final payment = _payment;
    if (payment == null || payment.isPaid || _checking) return;

    setState(() => _checking = true);
    try {
      final next = await _tickets.syncPayment(payment.id, widget.event);
      if (!mounted) return;

      if (next == null) {
        if (!quiet) AppSnackbar.error('could_not_confirm_payment'.tr);
        return;
      }

      if (next.isPaid && next.ticket != null) {
        _countdownTimer?.cancel();
        _goToSuccess(next.ticket!.id);
        return;
      }

      setState(() => _payment = next);
      if (!quiet) AppSnackbar.warning('payment_not_confirmed_yet'.tr);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'QR_EXPIRED') {
        _countdownTimer?.cancel();
        setState(() {
          _error = 'qr_expired'.tr;
          _qrExpired = true;
          _countdown = '00:00';
        });
        return;
      }
      if (quiet) return;
      if (error.code == 'BAKONG_DAILY_LIMIT') {
        AppSnackbar.error('bakong_daily_limit'.tr);
        return;
      }
      if (error.code == 'PAYWAY_DOMAIN') {
        AppSnackbar.error('payway_domain_blocked'.tr);
        return;
      }
      AppSnackbar.error(error.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _generateNewQr() async {
    if (_checking) return;
    await _confirmPaid(quiet: true);
    if (!mounted || _payment?.isPaid == true) return;
    await _start();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    void tick() {
      final expiresAt = _payment?.qrExpiresAt;
      if (expiresAt == null) return;

      final remaining = expiresAt.difference(DateTime.now().toUtc());
      if (remaining.isNegative) {
        _countdownTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _countdown = '00:00';
          _qrExpired = true;
        });
        return;
      }

      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds.remainder(60);
      if (!mounted) return;
      setState(() {
        _countdown =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _goToSuccess(String ticketId) {
    Get.off(() => PaymentSuccessPage(event: widget.event, ticketId: ticketId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAbaPay ? 'pay_with_aba_pay'.tr : 'pay_with_khqr'.tr),
      ),
      body: _loading
          ? LoadingView(
              message: _isAbaPay
                  ? 'generating_aba_pay'.tr
                  : 'generating_khqr'.tr,
            )
          : _isAbaPay
          ? _buildAbaPayBody(context)
          : _buildKhqrBody(context),
    );
  }

  Widget _buildKhqrBody(BuildContext context) {
    final payment = _payment;
    final showExpiredActions = _qrExpired || _error != null;
    final merchant = payment?.merchantName ?? 'GoITC';
    final currency = (payment?.currency ?? widget.event.priceCurrency)
        .toUpperCase();
    final amount = payment?.amount ?? widget.event.priceAmount;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_error != null) ...[
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.error),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (payment != null)
                        KhqrCard(
                          receiverName: merchant,
                          amount: amount,
                          currency: currency,
                          qr: payment.qrCode ?? '',
                          expired: _qrExpired,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'method_khqr_sub'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _qrExpired
                            ? 'qr_expired'.tr
                            : 'qr_will_be_expired'.trParams({
                                'time': _countdown,
                              }),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _qrExpired || _countdown == '00:00'
                              ? AppTheme.error
                              : AppTheme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: showExpiredActions
                ? FilledButton(
                    onPressed: _checking ? null : _generateNewQr,
                    child: _checking
                        ? _ButtonSpinner(label: 'checking_payment'.tr)
                        : Text('generate_new_qr'.tr),
                  )
                : FilledButton(
                    onPressed: _checking ? null : () => _confirmPaid(),
                    child: _checking
                        ? _ButtonSpinner(label: 'checking_payment'.tr)
                        : Text('i_have_paid'.tr),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbaPayBody(BuildContext context) {
    final payment = _payment;
    final showExpiredActions = _qrExpired || _error != null;
    final qr = payment?.qrCode ?? '';

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_error != null) ...[
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.error),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Image.asset('assets/payments/aba_pay.png', width: 140),
                      const SizedBox(height: 20),
                      if (qr.isNotEmpty)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: QrImageView(
                              key: const Key('aba_payway_qr'),
                              data: qr,
                              size: 240,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'scan_aba_pay_qr'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'aba_pay_sandbox_hint'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _qrExpired
                            ? 'qr_expired'.tr
                            : 'qr_will_be_expired'.trParams({
                                'time': _countdown,
                              }),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _qrExpired || _countdown == '00:00'
                              ? AppTheme.error
                              : AppTheme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: showExpiredActions
                ? FilledButton(
                    onPressed: _checking ? null : _generateNewQr,
                    child: _checking
                        ? _ButtonSpinner(label: 'checking_payment'.tr)
                        : Text('generate_new_qr'.tr),
                  )
                : FilledButton(
                    onPressed: _checking ? null : () => _confirmPaid(),
                    child: _checking
                        ? _ButtonSpinner(label: 'checking_payment'.tr)
                        : Text('i_have_paid'.tr),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: dark ? AppTheme.primary : Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
