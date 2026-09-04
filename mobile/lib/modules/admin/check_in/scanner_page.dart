import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/admin/check_in/check_in_controller.dart';
import 'package:itc_events/modules/admin/check_in/widgets/check_in_result_card.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminScanerPage extends StatefulWidget {
  const AdminScanerPage({super.key});

  @override
  State<AdminScanerPage> createState() => _AdminScanerPageState();
}

class _AdminScanerPageState extends State<AdminScanerPage> {
  final MobileScannerController _scanner = MobileScannerController();
  late final AdminCheckInController _checkIn;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _checkIn = Get.put(
      AdminCheckInController(apiClient: Get.find<ApiClient>()),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    if (Get.isRegistered<AdminCheckInController>()) {
      Get.delete<AdminCheckInController>();
    }
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _checkIn.isSubmitting.value) return;

    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (code == null) return;

    _busy = true;
    try {
      await _scanner.stop();
    } catch (_) {}
    await _checkIn.submit(code, method: 'qr');
    if (mounted) setState(() {});
  }

  Future<void> _scanAgain() async {
    _checkIn.clearResult();
    _busy = false;
    if (mounted) setState(() {});
    try {
      await _scanner.start();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            onPressed: () => _scanner.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => _scanner.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Place the QR code inside the box',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Obx(() {
            if (!_checkIn.isSubmitting.value) {
              return const SizedBox.shrink();
            }
            return const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }),
          Obx(() {
            final result = _checkIn.lastResult.value;
            final error = _checkIn.errorMessage.value;
            if (result == null && error == null) {
              return const SizedBox.shrink();
            }

            return ColoredBox(
              color: const Color(0x99000000),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (result != null) CheckInResultCard(outcome: result),
                        if (error != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                error,
                                style: const TextStyle(color: AppTheme.error),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _scanAgain,
                            child: const Text('Scan next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
