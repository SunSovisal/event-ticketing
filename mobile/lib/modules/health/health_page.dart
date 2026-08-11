import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/config/app_config.dart';
import 'package:itc_events/modules/health/health_controller.dart';

/// shows whether GET /api/v1/health succeeded.
class HealthPage extends GetView<HealthController> {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF3F4F6, // grey
      ), 
      appBar: AppBar(
        title: const Text('ITC Events'),
        backgroundColor: const Color(0xFF2563EB), // primary blue
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                // Obx rebuilds when controller.status / message change.
                final status = controller.status.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(status), size: 56, color: _colorFor(status)),
                    const SizedBox(height: 16),
                    Text(
                      controller.message.value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    // show URL so debugging wrong base URL is easy on simulator.
                    Text(
                      AppConfig.apiBaseUrl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (status == HealthStatus.loading)
                      const CircularProgressIndicator()
                    else
                      FilledButton(
                        onPressed: controller.checkHealth,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Check again'),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(HealthStatus status) {
    switch (status) {
      case HealthStatus.connected:
        return Icons.check_circle_outline;
      case HealthStatus.error:
        return Icons.error_outline;
      case HealthStatus.loading:
        return Icons.sync;
      case HealthStatus.idle:
        return Icons.cloud_outlined;
    }
  }

  Color _colorFor(HealthStatus status) {
    switch (status) {
      case HealthStatus.connected:
        return const Color(0xFF16A34A); // success green
      case HealthStatus.error:
        return const Color(0xFFDC2626); // error red
      case HealthStatus.loading:
      case HealthStatus.idle:
        return const Color(0xFF2563EB); // primary blue
    }
  }
}
