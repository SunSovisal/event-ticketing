import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Official KHQR card (NBC KHQR Card Guideline).
///
/// Ratio 20:29, Bakong Bravery Red header, Nunito Sans, left-aligned
/// receiver name / amount / currency, QR branding in the safe area.
class KhqrCard extends StatelessWidget {
  const KhqrCard({
    super.key,
    required this.receiverName,
    required this.amount,
    required this.currency,
    required this.qr,
    this.expired = false,
    this.width,
  });

  static const aspectRatio = 20 / 29;
  static const bakongBraveryRed = Color(0xFFE1232E);
  static const ravenDarkBlack = Color(0xFF000000);
  static const pearlWhite = Color(0xFFFFFFFF);
  static const _fontFamily = 'NunitoSans';

  final String receiverName;
  final double amount;
  final String currency;
  final String qr;
  final bool expired;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 300.0;
        final cardWidth = width ?? math.min(maxWidth, 300.0);
        final height = cardWidth / aspectRatio;
        final receiverNameFontSize = height * 0.03;
        final amountFontSize = height * 0.065;
        final currencyFontSize = height * 0.03;
        final headerHeight = height * 0.12;
        final qrHorizontalMargin = height * 0.10;
        final qrVerticalMargin = height * 0.08;
        final currencyCode = currency.toUpperCase();
        final amountText = formatKhqrAmount(amount, currency: currencyCode);
        final showAmount = amountText.isNotEmpty;

        return Center(
          child: Container(
            key: const Key('khqr_card'),
            width: cardWidth,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height * 0.045),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: Offset.zero,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: headerHeight,
                  color: bakongBraveryRed,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(
                    horizontal: cardWidth * 0.22,
                    vertical: headerHeight * 0.28,
                  ),
                  child: SvgPicture.string(
                    _khqrLogoSvg,
                    key: const Key('khqr_logo'),
                    height: headerHeight * 0.44,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    colorFilter: const ColorFilter.mode(
                      pearlWhite,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: bakongBraveryRed,
                    child: ClipPath(
                      clipper: _KhqrCardHeaderClipper(aspectRatio: aspectRatio),
                      child: ColoredBox(
                        color: pearlWhite,
                        child: Column(
                          children: [
                            SizedBox(height: height * 0.05),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: height * 0.08,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  receiverName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: receiverNameFontSize,
                                    color: ravenDarkBlack,
                                    height: 1.2,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: height * 0.08,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  if (showAmount)
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          amountText,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: _fontFamily,
                                            fontWeight: FontWeight.w700,
                                            fontSize: amountFontSize,
                                            color: ravenDarkBlack,
                                            height: 1,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (showAmount) const SizedBox(width: 6),
                                  Text(
                                    currencyCode,
                                    style: TextStyle(
                                      fontFamily: _fontFamily,
                                      fontSize: currencyFontSize,
                                      color: ravenDarkBlack,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: height * 0.04),
                            CustomPaint(
                              painter: _DashedLineHorizontalPainter(
                                aspectRatio: aspectRatio,
                              ),
                              size: Size(cardWidth, 1),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: qrHorizontalMargin,
                                  vertical: qrVerticalMargin,
                                ),
                                child: Opacity(
                                  opacity: expired ? 0.08 : 1,
                                  child: _KhqrCodeView(
                                    payload: qr,
                                    currency: currencyCode,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KhqrCodeView extends StatelessWidget {
  const _KhqrCodeView({required this.payload, required this.currency});

  final String payload;
  final String currency;

  String get _symbolAsset => currency == 'KHR'
      ? 'assets/khqr/riel_symbol.png'
      : 'assets/khqr/dollar_symbol.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        if (payload.isEmpty) {
          return const ColoredBox(color: KhqrCard.pearlWhite);
        }

        final symbolSize = size * 0.22;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ColoredBox(
                    color: KhqrCard.pearlWhite,
                    child: QrImageView(
                      data: payload,
                      size: size,
                      padding: const EdgeInsets.all(6),
                      backgroundColor: KhqrCard.pearlWhite,
                      version: QrVersions.auto,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      gapless: true,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: KhqrCard.ravenDarkBlack,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: KhqrCard.ravenDarkBlack,
                      ),
                    ),
                  ),
                  Image.asset(
                    _symbolAsset,
                    width: symbolSize,
                    height: symbolSize,
                    filterQuality: FilterQuality.high,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashedLineHorizontalPainter extends CustomPainter {
  _DashedLineHorizontalPainter({required this.aspectRatio});

  final double aspectRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final dashWidth = size.width * 0.03 * aspectRatio;
    final dashSpace = size.width * 0.02 * aspectRatio;
    final paint = Paint()
      ..color = KhqrCard.ravenDarkBlack
      ..strokeWidth = 0.2;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KhqrCardHeaderClipper extends CustomClipper<Path> {
  _KhqrCardHeaderClipper({required this.aspectRatio});

  final double aspectRatio;

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.lineTo(width - (width * 0.12 * aspectRatio), 0);
    path.lineTo(width, height * 0.08 * aspectRatio);
    path.lineTo(width, height);
    path.lineTo(0, height);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Official KHQR wordmark (white, for the red header).
const _khqrLogoSvg = '''
<svg width="166" height="40" viewBox="0 0 166 40" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M107.798 14.5845V26.9495H95.4329C94.1647 26.9495 93.2136 25.9191 93.2136 24.7302V14.5845C93.2136 13.3163 94.244 12.3651 95.4329 12.3651H105.499C106.847 12.3651 107.798 13.3163 107.798 14.5845Z" fill="white"/>
<path d="M165.739 19.578H159.557C159.557 12.2065 153.533 6.18253 146.161 6.18253C140.296 6.18253 135.144 9.98717 133.4 15.5356C133.004 16.8831 132.766 18.2305 132.766 19.578V39.2353H132.607C129.278 39.2353 126.583 36.5404 126.583 33.2113V19.578H126.663C126.663 14.1881 128.882 9.03601 132.845 5.31064C136.491 1.90232 141.247 0 146.241 0C157.02 0 165.739 8.79822 165.739 19.578Z" fill="white"/>
<path d="M165.819 39.2353L157.1 39.3146L154.96 37.1745L150.204 32.4187L143.625 25.8398H152.344L165.819 39.2353Z" fill="white"/>
<path d="M109.859 33.132H91.232C88.9333 33.132 87.1103 31.309 87.1103 29.0103V10.3042C87.1103 8.00559 88.9333 6.18253 91.232 6.18253H109.859C112.157 6.18253 113.981 8.00559 113.981 10.3042V28.9311L120.163 35.1136V6.02401C120.163 2.69495 117.468 0 114.139 0H86.9517C83.6227 0 80.9277 2.69495 80.9277 6.02401V33.2113C80.9277 36.5404 83.6227 39.2353 86.9517 39.2353H116.041L109.859 33.132Z" fill="white"/>
<path d="M34.1625 39.3146H25.4435L7.21295 21.0048V39.3146H0V0H7.21295V17.5172L24.6509 0H33.2906L14.2674 18.8647L34.1625 39.3146Z" fill="white"/>
<path d="M66.7397 0H73.7941V39.3146H66.7397V22.1937H46.6068V39.2353H39.5524V0H46.6068V16.4075H66.7397V0Z" fill="white"/>
</svg>
''';

/// Thousand-separated amount, matching the KHQR card examples.
/// USD keeps two decimal places (`10.00`); KHR is a whole number (`1,300,000`).
String formatKhqrAmount(
  double amount, {
  String currency = '',
  bool alwaysShowDecimal = false,
}) {
  final showDecimal = alwaysShowDecimal || currency.toUpperCase() == 'USD';
  if (showDecimal) {
    return _groupThousands(amount.toStringAsFixed(2));
  }
  if (amount == amount.truncateToDouble()) {
    return _groupThousands(amount.toInt().toString());
  }

  var decimals = amount.toStringAsFixed(2);
  if (decimals.endsWith('0')) {
    decimals = decimals.substring(0, decimals.length - 1);
  }
  return _groupThousands(decimals);
}

String _groupThousands(String number) {
  final parts = number.split('.');
  final negative = parts[0].startsWith('-');
  final digits = negative ? parts[0].substring(1) : parts[0];
  final buffer = StringBuffer();
  if (negative) {
    buffer.write('-');
  }
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  if (parts.length > 1) {
    buffer.write('.');
    buffer.write(parts[1]);
  }
  return buffer.toString();
}
