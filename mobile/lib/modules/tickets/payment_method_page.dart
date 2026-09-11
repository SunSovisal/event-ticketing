import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/app/widgets/app_page_bar.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/tickets/khqr_checkout_page.dart';
import 'package:itc_events/modules/tickets/payment_method.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            'payment_methods'.tr,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _MethodCard(
            logoAsset: 'assets/payments/khqr.png',
            title: 'method_khqr'.tr,
            subtitle: 'method_khqr_sub'.tr,
            onTap: () => Get.to(
              () => KhqrCheckoutPage(
                event: event,
                method: PaymentMethodOption.khqr,
              ),
            ),
          ),
          if (event.hasAbaPay) ...[
            const SizedBox(height: 12),
            _MethodCard(
              logoAsset: 'assets/payments/aba_pay.png',
              title: 'method_aba_pay'.tr,
              subtitle: 'method_aba_pay_sub'.tr,
              onTap: () => Get.to(
                () => KhqrCheckoutPage(
                  event: event,
                  method: PaymentMethodOption.abaPay,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.logoAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String logoAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppTheme.isDark(context) ? 0.35 : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 32,
                  child: Image.asset(logoAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
