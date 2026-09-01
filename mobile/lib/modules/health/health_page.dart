import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/config/app_config.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/health/health_controller.dart';

/// shows whether GET /api/v1/health succeeded.
class HealthPage extends GetView<HealthController> {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldOf(context),
      appBar: AppBar(
        title: Text('GoITC'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Obx(() {
                // Obx rebuilds when controller.status / message change.
                final status = controller.status.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(status), size: 56, color: _colorFor(status)),
                    SizedBox(height: 16),
                    Text(
                      controller.message.value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    // show URL so debugging wrong base URL is easy on simulator.
                    Text(
                      AppConfig.apiBaseUrl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                    SizedBox(height: 24),
                    if (status == HealthStatus.loading)
                      CircularProgressIndicator()
                    else
                      FilledButton(
                        onPressed: controller.checkHealth,
                        child: Text('Check again'),
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
        return AppTheme.success;
      case HealthStatus.error:
        return AppTheme.error;
      case HealthStatus.loading:
      case HealthStatus.idle:
        return AppTheme.primary;
    }
  }
}
